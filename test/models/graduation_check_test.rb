require "test_helper"

class GraduationCheckTest < ActiveSupport::TestCase
  FakeEnrollment = Struct.new(:course, :status)
  FakeUser = Struct.new(:thesis_completed) do
    def thesis_completed? = thesis_completed
  end

  # Catalog courses by key, or made-up ones: course("x", field: "economics", credits: 4, type: "on_campus")
  def course(key, **data)
    data.empty? ? Course.find(key) : Course.new(key: key, data: data.transform_keys(&:to_s))
  end

  def check(courses, status: "completed", thesis: false)
    enrollments = courses.map { |c| FakeEnrollment.new(c.is_a?(Course) ? c : course(c), status) }
    GraduationCheck.new(user: FakeUser.new(thesis), enrollments: enrollments)
  end

  def find(requirement, key)
    return requirement if requirement.key == key

    requirement.children.each do |child|
      found = find(child, key)
      return found if found
    end
    nil
  end

  def completed(check, key)
    check.sections.filter_map { |section| find(section, key) }.first.completed
  end

  test "the three areas add up to the credits needed to graduate" do
    areas = GraduationCheck::GENERAL_CREDITS + GraduationCheck::SPECIALIZED_CREDITS + GraduationCheck::THESIS_CREDITS
    assert_equal GraduationCheck::TOTAL_CREDITS, areas
    assert_equal 124, Enrollment::CREDITS_REQUIRED
  end

  test "nothing is met without courses" do
    empty = check([])

    assert_not empty.met?
    assert_equal 124, empty.remaining
    assert_equal %i[general specialized thesis schooling], empty.sections.map(&:key)
    assert empty.sections.none?(&:met?)
  end

  test "the seven required economics courses are 17 credits by distance learning" do
    required = Course.required_for_major("economics").select { |c| c.field == "economics" }
    assert_equal 7, required.size

    specialized = check(required).specialized
    assert_equal [ 17, 17 ], find(specialized, :required_courses).then { |r| [ r.completed, r.required ] }
    assert find(specialized, :required_courses).met?
    assert_equal 17, specialized.completed
    assert_equal 0, find(specialized, :electives).completed
  end

  test "each of the three fields needs two courses and six credits" do
    general = check(%w[phil101 logic101 lit101 stat101]).general

    assert_equal 8, find(general, :humanities_credits).completed
    assert_equal 3, find(general, :humanities_courses).completed
    assert find(general, :humanities_credits).met?
    # Statistics alone is 4 credits and one course in the natural sciences
    assert_equal 4, find(general, :natural_credits).completed
    assert_not find(general, :natural_credits).met?
    assert_not find(general, :natural_courses).met?
    assert find(general, :statistics).met?
    assert_equal 12, find(general, :three_fields).completed
  end

  test "statistics is not met without the course" do
    assert_not find(check(%w[math101 math102]).general, :statistics).met?
  end

  test "the required language is the one with the most credits and counts for 8" do
    languages = check(%w[eng101 eng102 eng103 eng107 ger101])

    assert_equal "english", languages.required_language
    assert_equal 8, completed(languages, :required_language)
    assert find(languages.general, :required_language).met?
    # German is an elective language: its 2 credits count on top
    assert_equal 10, languages.general.completed
  end

  test "elective languages count for 2 credits each, at most two languages" do
    extra = [
      course("eng", field: "foreign_language", language: "english", credits: 10),
      course("ger", field: "foreign_language", language: "german", credits: 6),
      course("chi", field: "foreign_language", language: "chinese", credits: 2),
      course("spa", field: "foreign_language", language: "spanish", credits: 2)
    ]

    # English is capped at 8; of the other three, two languages at 2 credits each
    assert_equal 12, check(extra).general.completed
  end

  test "schooling counts for at most 12 credits in the three fields" do
    courses = [
      course("a", field: "humanities", credits: 10, type: "on_campus"),
      course("b", field: "social", credits: 6, type: "media"),
      course("c", field: "natural", credits: 4, type: "distance")
    ]
    general = check(courses).general

    assert_equal 4, find(general, :three_fields_distance).completed
    assert_equal 16, find(general, :three_fields).completed
    # The per-field minimums count every credit, however it was earned
    assert_equal 10, find(general, :humanities_credits).completed
  end

  test "elective schooling counts for at most 28 credits and never as distance" do
    courses = [
      course("d", field: "economics", credits: 20, type: "distance"),
      course("s", field: "economics", credits: 40, type: "on_campus")
    ]
    specialized = check(courses).specialized

    assert_equal 20, find(specialized, :electives_distance).completed
    assert_equal 48, find(specialized, :electives).completed
    assert_equal 20, find(specialized, :specialized_distance).completed
  end

  test "schooling needs 30 credits, with media courses counting for at most 10" do
    courses = [
      course("s", field: "economics", credits: 18, type: "on_campus"),
      course("m", field: "humanities", credits: 14, type: "media")
    ]

    assert_equal 28, check(courses).schooling.completed
    assert_not check(courses).schooling.met?
  end

  test "the thesis counts once it is marked completed on the profile" do
    assert_equal 0, check([]).thesis.completed
    assert check([], thesis: true).thesis.met?
    assert_equal 116, check([], thesis: true).remaining
  end

  test "planned courses count toward the plan but not toward completed" do
    planned = check(%w[stat101 math101], status: "planned")
    natural = find(planned.general, :natural_credits)

    assert_equal [ 0, 6 ], [ natural.completed, natural.planned ]
    assert natural.on_track?
    assert_not natural.met?
    assert_not planned.general.all_on_track?
  end

  test "a plan that satisfies every rule is met" do
    courses = [
      course("h1", field: "humanities", credits: 6), course("h2", field: "humanities", credits: 4),
      course("s1", field: "social", credits: 6), course("s2", field: "social", credits: 4),
      course("n1", field: "natural", credits: 4), course("n2", field: "natural", credits: 4),
      course("stat101"),
      course("eng", field: "foreign_language", language: "english", credits: 8),
      *Course.required_for_major("economics").select { |c| c.field == "economics" },
      course("e1", field: "economics", credits: 23),
      course("e2", field: "economics", credits: 28, type: "on_campus"),
      course("g1", field: "humanities", credits: 8, type: "on_campus")
    ]
    full = check(courses, thesis: true)

    assert_equal [], full.sections.reject(&:all_met?).map(&:key)
    assert full.met?
    assert_equal 0, full.remaining
    assert_equal 124, full.total.completed
  end
end

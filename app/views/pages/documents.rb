# frozen_string_literal: true

module Views
  module Pages
    class Documents < Views::Base
      def view_template
        render Components::Layout.new do
          div(class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12") do
            render_header
            render_pdf_sections
            render_info
          end
        end
      end

      private

      def render_header
        div(class: "mb-8") do
          h1(class: "text-3xl font-bold text-gray-900 mb-2") { t(".title") }
          p(class: "text-gray-600") do
            t(".intro")
          end
        end
      end

      REPORT_CATEGORIES = [
        { key: "reports_humanities", name: "人文科学分野", label: "総合教育科目 ３分野科目" },
        { key: "reports_social", name: "社会科学分野", label: "総合教育科目 ３分野科目" },
        { key: "reports_natural", name: "自然科学分野", label: "総合教育科目 ３分野科目" },
        { key: "reports_foreign_lang", name: "外国語科目〔英語〕", label: "総合教育科目" },
        { key: "reports_economics", name: "経済学部専門教育科目", label: "専門教育科目" }
      ].freeze

      def render_pdf_sections
        div(class: "space-y-8") do
          render_pdf_card("syllabus", t(".syllabus_title"), t(".syllabus_text"))
          render_reports_section
          render_pdf_card("handbook", t(".handbook_title"), t(".handbook_text"))
        end
      end

      def render_pdf_card(key, title, description)
        div(class: "bg-white rounded-lg shadow-md p-6") do
          h2(class: "text-xl font-semibold text-gray-900 mb-2") { title }
          p(class: "text-sm text-gray-600 mb-4") { description }
          render Components::PdfViewer.new(key: key, label: "Upload PDF")
        end
      end

      def render_reports_section
        div do
          h2(class: "text-xl font-semibold text-gray-900 mb-1") { t(".reports_title") }
          p(class: "text-sm text-gray-600 mb-4") { t(".reports_text") }

          div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4") do
            REPORT_CATEGORIES.each do |cat|
              render_report_category_card(cat)
            end
          end
        end
      end

      def render_report_category_card(cat)
        div(class: "bg-white rounded-lg shadow-md p-5") do
          p(class: "text-xs text-gray-400 mb-1") { cat[:label] }
          h3(class: "text-sm font-semibold text-gray-900 mb-3") { cat[:name] }
          render Components::PdfViewer.new(key: cat[:key], label: "Upload PDF")
        end
      end

      def render_info
        div(class: "mt-8 bg-primary-50 border border-primary-200 rounded-lg p-4") do
          h3(class: "font-medium text-primary-900 mb-2") { t(".info_title") }
          p(class: "text-sm text-primary-800") do
            t(".info_text")
          end
        end
      end
    end
  end
end

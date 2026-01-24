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
          h1(class: "text-3xl font-bold text-gray-900 mb-2") { "Study Documents" }
          p(class: "text-gray-600") do
            "Upload your course documents here. Files are stored locally in your browser, not on our servers."
          end
        end
      end

      def render_pdf_sections
        div(class: "space-y-6") do
          render_pdf_card("syllabus", "履修案内 (Course Syllabus)", "The main course catalog and requirements guide")
          render_pdf_card("reports", "レポート課題集 (Report Topics)", "Collection of report assignments for all courses")
          render_pdf_card("handbook", "学習のしおり (Study Handbook)", "Guide for distance learning procedures")
        end
      end

      def render_pdf_card(key, title, description)
        div(class: "bg-white rounded-lg shadow-md p-6") do
          h2(class: "text-xl font-semibold text-gray-900 mb-2") { title }
          p(class: "text-sm text-gray-600 mb-4") { description }
          render Components::PdfViewer.new(key: key, label: "Upload PDF")
        end
      end

      def render_info
        div(class: "mt-8 bg-blue-50 border border-blue-200 rounded-lg p-4") do
          h3(class: "font-medium text-blue-900 mb-2") { "About local storage" }
          p(class: "text-sm text-blue-800") do
            "Your PDFs are stored in your browser's IndexedDB. They never leave your device. If you clear browser data, you'll need to re-upload."
          end
        end
      end
    end
  end
end

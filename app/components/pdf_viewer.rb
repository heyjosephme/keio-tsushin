# frozen_string_literal: true

class Components::PdfViewer < Components::Base
  def initialize(key:, label: "PDF Document", page: 1)
    @key = key
    @label = label
    @page = page
  end

  def view_template
    div(
      data: {
        controller: "pdf-viewer",
        pdf_viewer_key_value: @key,
        pdf_viewer_page_value: @page
      },
      class: "space-y-2"
    ) do
      render_label
      render_upload_section
      render_modal
    end
  end

  private

  def render_label
    label(class: "block text-sm font-medium text-gray-700") { @label }
  end

  def render_upload_section
    div(class: "flex items-center gap-3") do
      # File input
      input(
        type: "file",
        accept: "application/pdf",
        class: "block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-medium file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100",
        data: {
          pdf_viewer_target: "fileInput",
          action: "change->pdf-viewer#upload"
        }
      )

      # Upload status
      span(
        class: "hidden text-sm text-green-600",
        data: { pdf_viewer_target: "uploadStatus" }
      )

      # View button
      button(
        type: "button",
        class: "hidden px-3 py-1.5 text-sm font-medium text-indigo-600 bg-indigo-50 rounded-md hover:bg-indigo-100",
        data: {
          pdf_viewer_target: "viewButton",
          action: "click->pdf-viewer#view"
        }
      ) { "View" }

      # Remove button
      button(
        type: "button",
        class: "text-sm text-red-600 hover:text-red-800",
        data: { action: "click->pdf-viewer#remove" }
      ) { "Remove" }
    end
  end

  def render_modal
    div(
      class: "hidden fixed inset-0 z-50 bg-black bg-opacity-50 flex items-center justify-center p-4",
      data: {
        pdf_viewer_target: "modal",
        action: "click->pdf-viewer#closeOnBackdrop"
      }
    ) do
      div(class: "bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] flex flex-col") do
        render_modal_header
        render_modal_body
      end
    end
  end

  def render_modal_header
    div(class: "flex items-center justify-between px-4 py-3 border-b") do
      # Page navigation
      div(class: "flex items-center gap-2") do
        button(
          type: "button",
          class: "p-1 rounded hover:bg-gray-100",
          data: { action: "click->pdf-viewer#prevPage" }
        ) { "← Prev" }

        span(
          class: "text-sm text-gray-600",
          data: { pdf_viewer_target: "pageInfo" }
        ) { "Page 1" }

        button(
          type: "button",
          class: "p-1 rounded hover:bg-gray-100",
          data: { action: "click->pdf-viewer#nextPage" }
        ) { "Next →" }
      end

      # Close button
      button(
        type: "button",
        class: "p-2 rounded hover:bg-gray-100",
        data: { action: "click->pdf-viewer#closeModal" }
      ) { "✕ Close" }
    end
  end

  def render_modal_body
    div(
      class: "flex-1 overflow-auto p-4 flex justify-center items-start bg-gray-100",
      data: { pdf_viewer_target: "container" }
    ) do
      canvas(
        class: "shadow-lg max-w-full",
        data: { pdf_viewer_target: "canvas" }
      )
    end
  end
end

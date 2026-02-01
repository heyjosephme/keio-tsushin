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
      }
    ) do
      render_upload_section
      render_modal
    end
  end

  private

  def render_upload_section
    # Hidden file input
    input(
      type: "file",
      accept: "application/pdf",
      class: "hidden",
      data: {
        pdf_viewer_target: "fileInput",
        action: "change->pdf-viewer#upload"
      }
    )

    # Empty state
    button(
      type: "button",
      class: "w-full flex flex-col items-center justify-center gap-1 py-3 rounded-lg border-2 border-dashed border-gray-200 text-gray-400 hover:border-indigo-300 hover:text-indigo-500 transition cursor-pointer",
      data: {
        pdf_viewer_target: "emptyState",
        action: "click->pdf-viewer#triggerUpload"
      }
    ) do
      span(class: "text-xl") { "📤" }
      span(class: "text-xs") { "Upload" }
    end

    # Uploaded state
    div(
      class: "hidden flex items-center justify-center gap-3",
      data: { pdf_viewer_target: "uploadedState" }
    ) do
      # View PDF
      button(
        type: "button",
        class: "text-2xl hover:scale-110 transition cursor-pointer",
        title: "View PDF",
        data: { action: "click->pdf-viewer#view" }
      ) { "📄" }

      # Replace PDF
      button(
        type: "button",
        class: "text-sm text-gray-400 hover:text-indigo-500 transition cursor-pointer",
        title: "Replace PDF",
        data: { action: "click->pdf-viewer#triggerUpload" }
      ) { "📤" }

      # Remove PDF
      button(
        type: "button",
        class: "text-sm text-gray-400 hover:text-red-500 transition cursor-pointer",
        title: "Remove PDF",
        data: { action: "click->pdf-viewer#remove" }
      ) { "✕" }
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

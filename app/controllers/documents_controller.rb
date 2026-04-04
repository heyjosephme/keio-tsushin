class DocumentsController < ApplicationController
  # GET /documents/:key
  def show
    blob = find_document(params[:key])
    if blob
      redirect_to rails_blob_path(blob, disposition: "inline")
    else
      head :not_found
    end
  end

  # POST /documents/:key
  def create
    file = params[:file]
    unless file&.content_type == "application/pdf"
      head :unprocessable_entity
      return
    end

    # Remove existing document with same key before attaching new one
    remove_document(params[:key])

    Current.user.documents.attach(
      io: file,
      filename: file.original_filename,
      content_type: "application/pdf",
      metadata: { key: params[:key] }
    )

    head :created
  end

  # DELETE /documents/:key
  def destroy
    if remove_document(params[:key])
      head :no_content
    else
      head :not_found
    end
  end

  # GET /documents/check/:key
  def check
    blob = find_document(params[:key])
    render json: { exists: blob.present? }
  end

  private

  def find_document(key)
    Current.user.documents.blobs.find_by("active_storage_blobs.metadata LIKE ?", "%\"key\":\"#{key}\"%")
  end

  def remove_document(key)
    blob = find_document(key)
    return false unless blob

    attachment = Current.user.documents.attachments.find_by(blob_id: blob.id)
    attachment&.purge
    true
  end
end

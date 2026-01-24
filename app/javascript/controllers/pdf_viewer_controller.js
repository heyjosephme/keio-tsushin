import { Controller } from "@hotwired/stimulus"
import Dexie from "dexie"

// window.pdfjsLib is loaded globally from CDN in application layout

// Initialize IndexedDB
const db = new Dexie("KeioTsushinPDFs")
db.version(1).stores({
  pdfs: "key"
})

export default class extends Controller {
  static targets = ["fileInput", "modal", "canvas", "uploadStatus", "viewButton", "pageInfo"]
  static values = { key: String, page: { type: Number, default: 1 } }

  pdfDoc = null
  currentPage = 1

  connect() {
    this.checkExistingPdf()
    this.checkAutoOpen()
  }

  // Auto-open PDF if URL has matching params
  checkAutoOpen() {
    const params = new URLSearchParams(window.location.search)
    const pdfKey = params.get("pdf")
    const page = parseInt(params.get("page")) || 1

    if (pdfKey === this.keyValue) {
      this.pageValue = page
      // Small delay to ensure DOM is ready
      setTimeout(() => this.view(), 100)
    }
  }

  async checkExistingPdf() {
    const pdf = await db.pdfs.get(this.keyValue)
    if (pdf) {
      this.showUploadedState()
    }
  }

  async upload(event) {
    const file = event.target.files[0]
    if (!file || file.type !== "application/pdf") {
      alert("Please select a PDF file")
      return
    }

    try {
      const arrayBuffer = await file.arrayBuffer()
      await db.pdfs.put({
        key: this.keyValue,
        data: arrayBuffer,
        name: file.name,
        uploadedAt: new Date().toISOString()
      })
      this.showUploadedState()
    } catch (error) {
      console.error("Failed to save PDF:", error)
      alert("Failed to save PDF")
    }
  }

  showUploadedState() {
    if (this.hasUploadStatusTarget) {
      this.uploadStatusTarget.textContent = "PDF saved"
      this.uploadStatusTarget.classList.remove("hidden")
    }
    if (this.hasViewButtonTarget) {
      this.viewButtonTarget.classList.remove("hidden")
    }
  }

  async view() {
    const record = await db.pdfs.get(this.keyValue)
    if (!record) {
      alert("PDF not found. Please upload first.")
      return
    }

    try {
      this.pdfDoc = await window.pdfjsLib.getDocument({ data: record.data }).promise
      this.currentPage = this.pageValue || 1
      this.modalTarget.classList.remove("hidden")
      await this.renderPage(this.currentPage)
    } catch (error) {
      console.error("Failed to load PDF:", error)
      alert("Failed to load PDF")
    }
  }

  async renderPage(pageNum) {
    if (!this.pdfDoc) return

    const page = await this.pdfDoc.getPage(pageNum)
    const canvas = this.canvasTarget
    const context = canvas.getContext("2d")

    const viewport = page.getViewport({ scale: 1.5 })
    canvas.height = viewport.height
    canvas.width = viewport.width

    await page.render({
      canvasContext: context,
      viewport: viewport
    }).promise

    if (this.hasPageInfoTarget) {
      this.pageInfoTarget.textContent = `Page ${pageNum} of ${this.pdfDoc.numPages}`
    }
  }

  prevPage() {
    if (this.currentPage > 1) {
      this.currentPage--
      this.renderPage(this.currentPage)
    }
  }

  nextPage() {
    if (this.pdfDoc && this.currentPage < this.pdfDoc.numPages) {
      this.currentPage++
      this.renderPage(this.currentPage)
    }
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    this.pdfDoc = null
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.closeModal()
    }
  }

  async remove() {
    if (!confirm("Remove this PDF from local storage?")) return

    await db.pdfs.delete(this.keyValue)
    if (this.hasUploadStatusTarget) {
      this.uploadStatusTarget.classList.add("hidden")
    }
    if (this.hasViewButtonTarget) {
      this.viewButtonTarget.classList.add("hidden")
    }
    if (this.hasFileInputTarget) {
      this.fileInputTarget.value = ""
    }
  }
}

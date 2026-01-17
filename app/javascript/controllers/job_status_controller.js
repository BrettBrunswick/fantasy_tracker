import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator", "message"]

  connect() {
    this.poll()
    this.pollInterval = setInterval(() => this.poll(), 3000)
  }

  disconnect() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
    }
  }

  async poll() {
    try {
      const response = await fetch("/jobs/status")
      const data = await response.json()

      this.updateUI(data)
    } catch (error) {
      console.error("Failed to fetch job status:", error)
    }
  }

  updateUI(data) {
    const hasActive = data.active.length > 0
    const hasRecent = data.recent.length > 0

    if (hasActive) {
      this.showProcessing(data.active[0])
    } else if (hasRecent) {
      this.showCompleted(data.recent[0])
    } else {
      this.hide()
    }
  }

  showProcessing(job) {
    this.indicatorTarget.style.display = "block"
    this.indicatorTarget.className = "job-status job-status--processing"
    this.messageTarget.textContent = `${job.job_type}: Processing...`
  }

  showCompleted(job) {
    this.indicatorTarget.style.display = "block"

    if (job.status === "completed") {
      this.indicatorTarget.className = "job-status job-status--completed"
      this.messageTarget.textContent = `${job.job_type}: Completed!`
    } else {
      this.indicatorTarget.className = "job-status job-status--failed"
      this.messageTarget.textContent = `${job.job_type}: Failed - ${job.message || "Unknown error"}`
    }

    // Auto-dismiss after 5 seconds
    setTimeout(() => this.dismiss(job.id), 5000)
  }

  hide() {
    this.indicatorTarget.style.display = "none"
  }

  async dismiss(jobId) {
    try {
      await fetch(`/jobs/${jobId}/dismiss`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })
      this.hide()
    } catch (error) {
      console.error("Failed to dismiss job:", error)
    }
  }
}

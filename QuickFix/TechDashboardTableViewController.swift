//
//  TechDashboardTableViewController.swift
//  QuickFix
//
//  Created by Faisal Alsinini on 28/12/2025.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore
import DGCharts

final class TechDashboardTableViewController: UITableViewController {

    private let db = Firestore.firestore()

    private var totalAssigned = 0
    private var inProgressTasks = 0
    private var completedTasks = 0
    private var avgResolutionText = "-"
    private var weeklyCompleted: [Double] = [0, 0, 0, 0]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none

        fetchDashboardDataForTechnician()
        fetchWeeklyCompletedLast30Days()

    }

    private func seed20TasksLast30Days_GuaranteedCompleted() {
        guard let techUID = Auth.auth().currentUser?.uid else {
            print("No logged-in user")
            return
        }

        let batch = db.batch()
        let calendar = Calendar.current
        let now = Date()

        let completedCount = 12
        let totalCount = 20

        for i in 0..<totalCount {
            let docRef = db.collection("tasks").document()

            let randomDaysAgo = Int.random(in: 0...29)
            let assignedDate = calendar.date(byAdding: .day, value: -randomDaysAgo, to: now)!

            let isCompleted = (i < completedCount)

            var data: [String: Any] = [
                "assignedTo": techUID,
                "assignedAt": Timestamp(date: assignedDate),
                "status": isCompleted ? "completed" : "in_progress"
            ]

            if isCompleted {
                let completionHours = Int.random(in: 1...72)
                var completedDate = calendar.date(byAdding: .hour, value: completionHours, to: assignedDate)!
                if completedDate > now { completedDate = now }
                data["completedAt"] = Timestamp(date: completedDate)
            }

            batch.setData(data, forDocument: docRef)
        }

        batch.commit { [weak self] error in
            if let error = error {
                print("❌ Seed failed:", error)
            } else {
                print("✅ Seeded 20 tasks (12 completed).")
                self?.fetchDashboardDataForTechnician()
                self?.fetchWeeklyCompletedLast30Days()
            }
        }
    }

    private func fetchDashboardDataForTechnician() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No logged-in user")
            return
        }

        db.collection("tasks")
            .whereField("assignedTo", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("Firestore error: \(error)")
                    return
                }

                let docs = snapshot?.documents ?? []

                var total = 0
                var inProgress = 0
                var completed = 0

                var totalResolutionSeconds: TimeInterval = 0
                var completedWithDates = 0

                for doc in docs {
                    total += 1
                    let data = doc.data()

                    let status = (data["status"] as? String ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()

                    switch status {
                    case "in_progress":
                        inProgress += 1

                    case "completed":
                        completed += 1

                        if let assignedAt = (data["assignedAt"] as? Timestamp)?.dateValue(),
                           let completedAt = (data["completedAt"] as? Timestamp)?.dateValue() {
                            let diff = completedAt.timeIntervalSince(assignedAt)
                            if diff > 0 {
                                totalResolutionSeconds += diff
                                completedWithDates += 1
                            }
                        }

                    default:
                        break
                    }
                }

                self.totalAssigned = total
                self.completedTasks = completed
                self.inProgressTasks = inProgress

                if completedWithDates > 0 {
                    let avgSeconds = totalResolutionSeconds / Double(completedWithDates)
                    self.avgResolutionText = self.formatDuration(avgSeconds)
                } else {
                    self.avgResolutionText = "-"
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    private func fetchWeeklyCompletedLast30Days() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let now = Date()
        let fromDate = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let cal = Calendar.current

        db.collection("tasks")
            .whereField("assignedTo", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("Weekly fetch error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                var buckets: [Double] = [0, 0, 0, 0]

                for doc in docs {
                    let data = doc.data()

                    let status = (data["status"] as? String ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                    guard status == "completed" else { continue }

                    guard let completedAt = (data["completedAt"] as? Timestamp)?.dateValue() else { continue }
                    guard completedAt >= fromDate && completedAt <= now else { continue }

                    let daysAgoRaw = cal.dateComponents([.day], from: completedAt, to: now).day ?? 0
                    let daysAgo = max(0, daysAgoRaw)   // protect future timestamps
                    guard daysAgo <= 30 else { continue }

                    let weekIndex = min(3, max(0, (30 - daysAgo) / 7))
                    buckets[weekIndex] += 1
                }

                self.weeklyCompleted = buckets
                print("weeklyCompleted =", buckets)

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let days = totalMinutes / (60 * 24)
        let hours = (totalMinutes % (60 * 24)) / 60
        let minutes = totalMinutes % 60

        if days > 0 { return "\(days) days" }
        if hours > 0 { return "\(hours) hrs" }
        return "\(minutes) mins"
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {

        applyBorderToAllViews(in: cell.contentView)

        if let totalLbl = cell.contentView.viewWithTag(201) as? UILabel {
            totalLbl.text = "\(totalAssigned)"
        }
        if let inProgressLbl = cell.contentView.viewWithTag(205) as? UILabel {
            inProgressLbl.text = "\(inProgressTasks)"
        }
        if let completedLbl = cell.contentView.viewWithTag(202) as? UILabel {
            completedLbl.text = "\(completedTasks)"
        }
        if let avgLbl = cell.contentView.viewWithTag(204) as? UILabel {
            avgLbl.text = avgResolutionText
        }

        if indexPath.row == 3,
           let chart = cell.contentView.viewWithTag(999) as? BarChartView {

            configureBarChart(chart, values: weeklyCompleted)
            chart.fitBars = true
            chart.notifyDataSetChanged()
        }
    }

    private func applyBorderToAllViews(in rootView: UIView) {
        if rootView.tag == 999 { return }

        for subview in rootView.subviews {
            if subview.tag == 999 { continue }

            if subview is UILabel ||
                subview is UIImageView ||
                subview is UIButton ||
                subview is UITextField ||
                subview is UITextView {
                applyBorderToAllViews(in: subview)
                continue
            }

            subview.layer.cornerRadius = 12
            subview.layer.borderWidth = 1
            subview.layer.borderColor = UIColor.systemGray5.cgColor
            subview.backgroundColor = .systemBackground
            subview.clipsToBounds = true

            applyBorderToAllViews(in: subview)
        }
    }

    private func configureBarChart(_ chart: BarChartView, values: [Double]) {
        let entries = values.enumerated().map { index, value in
            BarChartDataEntry(x: Double(index), y: value)
        }

        let set = BarChartDataSet(entries: entries, label: "")
        set.colors = [UIColor.systemGray4]
        set.drawValuesEnabled = false
        set.highlightEnabled = true
        set.highlightColor = UIColor.systemBlue
        set.highlightLineWidth = 1.0

        let data = BarChartData(dataSet: set)
        data.barWidth = 0.55
        chart.data = data

        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values: ["Week 1", "Week 2", "Week 3", "Week 4"])
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.drawAxisLineEnabled = false
        chart.xAxis.granularity = 1
        chart.xAxis.labelTextColor = .secondaryLabel

        chart.leftAxis.drawGridLinesEnabled = false
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.axisMaximum = max(1, (values.max() ?? 0) + 1) // ✅ important
        chart.leftAxis.labelTextColor = .secondaryLabel
        chart.rightAxis.enabled = false

        chart.legend.enabled = false
        chart.chartDescription.enabled = false

        chart.isUserInteractionEnabled = true
        chart.highlightPerTapEnabled = true
        chart.highlightPerDragEnabled = true
        chart.dragEnabled = true
        chart.setScaleEnabled(true)
        chart.pinchZoomEnabled = true
        chart.doubleTapToZoomEnabled = true

        chart.extraTopOffset = 8
        chart.extraBottomOffset = 8
        chart.extraLeftOffset = 8
        chart.extraRightOffset = 8

        chart.animate(yAxisDuration: 0.4)
    }
}


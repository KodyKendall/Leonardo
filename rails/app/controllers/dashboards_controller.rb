class DashboardsController < ApplicationController
  def index
  end

  def metrics
    render json: {
      # Tender metrics
      total_tenders: Tender.count,
      draft_tenders: Tender.where(status: 'draft').count,
      
      # Project metrics
      active_projects: Project.where(project_status: 'active').count,
      inactive_projects: Project.where.not(project_status: 'active').count,
      
      # Claim metrics
      pending_claims: Claim.where(claim_status: 'pending').count,
      approved_claims: Claim.where(claim_status: 'approved').count,
      draft_claims: Claim.where(claim_status: 'draft').count,
      
      # Budget metrics
      total_budget: Project.sum(:budget_total).to_f,
      total_spent: Project.sum(:actual_spend).to_f,
      
      # Alerts
      alerts: generate_risk_alerts
    }
  end

  private

  def generate_risk_alerts
    alerts = []

    # Check for claims with high amounts due
    overdue_claims = Claim.where('claim_status = ? AND amount_due > 0', 'pending')
                           .sum(:amount_due)
    
    if overdue_claims > 0
      alerts << {
        type: 'danger',
        title: 'Outstanding Claims',
        message: "You have £#{overdue_claims.round(2)} in pending claim amounts.",
        link: claims_path
      }
    end

    # Check for budget overruns
    projects_over_budget = Project.where("actual_spend > budget_total AND budget_total > 0")
    
    projects_over_budget.each do |project|
      overage = project.actual_spend - project.budget_total
      alerts << {
        type: 'danger',
        title: "Budget Overrun: #{project.rsb_number}",
        message: "Project has exceeded budget by £#{overage.round(2)}.",
        link: project_path(project)
      }
    end

    # Check for active variation orders awaiting approval
    pending_vos = VariationOrder.where(vo_status: 'draft').count
    
    if pending_vos > 0
      alerts << {
        type: 'warning',
        title: 'Pending Variation Orders',
        message: "#{pending_vos} variation order(s) awaiting approval.",
        link: variation_orders_path
      }
    end

    # Check for projects nearing their end dates
    upcoming_end = Project.where('project_end_date <= ? AND project_end_date > ?', 
                                  30.days.from_now, Time.current)
    
    if upcoming_end.count > 0
      alerts << {
        type: 'warning',
        title: 'Projects Nearing Completion',
        message: "#{upcoming_end.count} project(s) ending within the next 30 days.",
        link: projects_path
      }
    end

    alerts
  end
end

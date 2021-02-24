#require "wizard_steps/version"
require "active_support/concern"
#require "wizard_steps/store"
#require "wizard_steps/step"
#require "wizard_steps/base"
Dir["../lib/wizard_steps/*.rb"].each { |file| require file }

module WizardSteps
  extend ActiveSupport::Concern

  included do
    class_attribute :wizard_class
    helper_method :wizard, :current_step, :step_path
  end

  def index
    #skip_policy_scope
    redirect_to step_path(wizard_class.first_key)
  end

  def show
    #authorize wizard
  end

  def update
    #authorize wizard
    current_step.assign_attributes step_params

    if current_step.save!
      if wizard.complete?
        wizard.complete! { |result| on_complete(result) }
      else
        redirect_to(next_step_path)
      end
    else
      render :show
    end
  end

  def completed
    #authorize wizard_class
  end

private

  def wizard
    @wizard ||= wizard_class.new(wizard_store, params[:id], context: wizard_context)
  end

  def current_step
    @current_step ||= wizard.find_current_step
  end

  def next_step_path
    if (next_key = wizard.next_key)
      step_path next_key
    elsif (invalid_step = wizard.first_invalid_step)
      step_path invalid_step
    end
  end

  def step_path(step = params[:id])
    raise(NotImplementedError)
  end

  def step_params
    return {} unless params.key?(step_param_key)

    params.require(step_param_key).permit current_step.attributes.keys
  end

  def step_param_key
    current_step.class.model_name.param_key
  end

  def wizard_store
    ::WizardSteps::Store.new(session_store)
  end

  def session_store
    session[wizard_store_key] ||= {}
  end

  def wizard_context
    {}
  end

  def wizard_store_key
    raise(NotImplementedError)
  end

  def on_complete(_result)
    redirect_to(action: :completed)
  end
end
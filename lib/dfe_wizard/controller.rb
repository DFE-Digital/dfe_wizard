module DFEWizard
  module Controller
    extend ActiveSupport::Concern

    included do
      class_attribute :wizard_class
      before_action :load_wizard, :load_current_step, only: %i[show update]
    end

    def index
      query_params = request.query_parameters
      redirect_to step_path(wizard_class.first_key, query_params)
    end

    def show
      # current_step loaded via before_action
    end

    def update
      @current_step.assign_attributes step_params

      if @current_step.save
        redirect_to next_step_path

        # Needs to occur after redirect because it purges data after submission
        @wizard.complete!
      end
    end

    def completed
      # current_step is loaded via before_action
    end

  private

    def wizard_store
      Store.new backing_store
    end

    def load_wizard
      @wizard = wizard_class.new(wizard_store, params[:id])
    end

    def load_current_step
      @current_step = @wizard.find_current_step
    end

    def next_step_path
      if (next_key = @wizard.next_key)
        step_path next_key
      elsif (invalid_step = @wizard.first_invalid_step)
        step_path invalid_step
      else # all steps valid so completed
        completed_step_path
      end
    end

    def first_step_path
      step_path(wizard_class.steps.first.key)
    end

    def completed_step_path
      step_path :completed
    end

    def step_params
      params.require(step_param_key).permit @current_step.attributes.keys
    end

    def step_param_key
      @current_step.class.model_name.param_key
    end
  end
end

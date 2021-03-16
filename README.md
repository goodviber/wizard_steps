# WizardSteps

TODO: describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wizard_steps'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install wizard_steps

## Usage

Firstly, there is a pre-requisite of knowing what a multi-step form is if you don't already. A great resource is [this railscast](http://railscasts.com/episodes/217-multistep-forms).

The gem is fits a typical MVC style (model-view-controller)

## Model

List your steps in a wizard.rb file, located at the base of your multi-step folder. Take the following file structure below as an example for a module to create a user:

```
|models
|__user_creation
|  |__steps
|  |  |__name.rb
|  |  |__date_of_birth.rb
|  |  |__gender.rb
|  |  |__review_answers.rb
|  |__wizard.rb  <--- list your steps here
|__user.rb
```
For the above example with a User class in user.rb, a user_creation folder with four steps, lets have a look at what the wizard.rb would look like:

```
# app/models/user_creation/wizard.rb

module UserCreation
  class Wizard < WizardSteps::Base
    self.steps = [
      Steps::Name,
      Steps::DateOfBirth,
      Steps::Gender,
      Steps::ReviewAnswers
    ].freeze

  private

    def do_complete
      User.create!(
        first_name: @store.data["first_name"],
        last_name: @store.data["last_name"],
        date_of_birth: @store.data["date_of_birth"],
        gender: @store.data["gender"],
      )
    end
  end
end
```

You create a module to wrap the multi step form. Inside this module, create a new wizard which derives from WizardSteps::Base, and register the steps you plan on using in the correct order.

The private method, `do_complete`, is what will be called **when the last step has been submitted**, in this example we are creating a User instance in the database. Note how `@store.data` is accessed.

In this example, our multi step form is for the User model, so we require various attributes in each step, such as Name, Date Of Birth and Gender, store them, review the answers, and if all is good, we submit.

Wait, but what does each step look like? Similarly to the above, it follows a modular pattern. Take the below as an example.

```
# app/models/user_creation/steps/name.rb

module UserCreation
  module Steps
    class Name < WizardSteps::Step

      attribute :first_name, :string
      attribute :last_name, :string

      validates :first_name, :last_name, presence: true

      def reviewable_answers
        {
          "name" => "#{first_name} #{last_name}"
        }
      end
    end
  end
end
```
The step name (`Name`) inherits from `WizardSteps::Step` which includes ActiveModel, so we can define and validate attributes in each class. The `reviewable_answers` method defines a hash that will be passed to the review_answers view.

### Date attribute

As the steps are ActiveModels, we need to include `ActiveRecord::AttributeAssignment` to simplify processing Rails date fields:

```
# models/user_creation/steps/date_of_birth.rb

module UserCreation
  module Steps
    class DateOfBirth < ::Wizard::Step
      include ActiveRecord::AttributeAssignment

      attribute :date_of_birth, :date

      validates :date_of_birth, presence: true

      def reviewable_answers
        {
          "date_of_birth" => date_of_birth,
        }
      end
    end
  end
end

# views/user_creation/steps/_date_of_birth.html.erb

<%= form_for current_step, url: step_path do |f| %>
    <%= f.date_field, :date_of_birth %>
<% end %>
```
## Review Answers

Your review_answers will look like this:

```
# models/user_creation/steps/review_answers.rb

module UserCreation
  module Steps
    class ReviewAnswers < WizardSteps::Step
      def answers_by_step
        @answers_by_step ||= @wizard.reviewable_answers_by_step
      end
    end
  end
end

# views/user_creation/steps/_review_answers.html.erb

<% f.object.answers_by_step.each do |step, answers| %>
    <% answers.each do |answer| %>
    # you have `step.key`, `answer.first`, `answer.last`
    # and you can link back to a `(step`)
    <% end %>
<% end %>
```

## Lets move onto the controller.

Your controller layout should follow:

```
|controllers
|__user_creation
|  |__steps_controller.rb
```

Yep, its that simple. And in the controller:

```
# app/controllers/user_creation/steps_controller.rb

module UserCreation
  class StepsController < ApplicationController
    include WizardSteps
    self.wizard_class = UserCreation::Wizard

  private

    def step_path(step = params[:id])
      user_creation_step_path(step)
    end

    def wizard_store_key
      :user_creation
    end

    def on_complete(user)
      redirect_to(<your custom route>)
    end
  end
end
```

Inside the module for your steps, you can see it follows a general controller layout deriving from ApplicationController.

And the views;

```
|views
|__user_creation
|  |__steps
|     |__ _form.html.erb
|     |__ _name.html.erb
|     |__ _date_of_birth.html.erb
|     |__ _gender.html.erb
|     |__ _review_answers.html.erb
|     |__show.html.erb
```

```
# app/views/user_creation/_name.html.erb
<%= f.govuk_fieldset legend: { text: "Name" } do %>
  <%= f.govuk_text_field :first_name, label: { text: 'First name' } %>
  <%= f.govuk_text_field :last_name, label: { text: 'Last name' } %>
<% end %>
```

```
# app/views/user_creation/show.html.erb
<%= render "form", current_step: current_step, wizard: wizard %>
```
The form partial can check for `wizard.previous_key` as a conditional for a back button, and `wizard.can_proceed?` for a continue/submit button.
The other key lines are:
```
<%= form_for current_step, url: step_path do |f| %>
    <%= render current_step.key, current_step: current_step, f: f %>
<% end >
```
As an example:

```
# app/views/user_creation/steps/_form.html.erb

<% if wizard.previous_key %>
  <% content_for(:back_button) do %>
  <%= back_link step_path(wizard.previous_key) %>
  <% end %>
<% end %>

<div class="govuk-grid-row">
  <div class="govuk-grid-column-two-thirds">
    <%= form_for current_step, url: step_path do |f| %>
      <%= f.govuk_error_summary %>

      <%= render current_step.key, current_step: current_step, f: f %>

      <% if wizard.can_proceed? %>
        <%= f.govuk_submit("Continue") %>
      <% end %>
    <% end %>
  </div>
</div>
```


And finally, in your routes

```
namespace :children_creation do
  resources :steps, only: %i[show update]
end
```

## Context

It is possible to include a `context` where a stepped model belongs_to another model, in order to pass the latter id (foreign_key) to the stepped model. As an example we have a DiaryEntry which belongs to a Placement:
```
# app/models/diary_entry.rb

class DiaryEntry < ApplicationRecord
  belongs_to :placement, optional: false, inverse_of: :diary_entries

  validates :event, presence: true
  validates :note, presence: true
end

# app/models/placement.rb

class Placement < ApplicationRecord
  has_many :diary_entries, inverse_of: :placement
  ...
end
```

The model structure follows:
```
|models
|__diary
|  |__steps
|  |  |__note.rb
|  |  |__event.rb
|  |  |__review_answers.rb
|  |__wizard.rb  <--- list your steps here
|__diary_entry.rb
|__placement.rb
```

In the controller we have a `placement_id` in `step_path` and `wizard_context`:
```
# app/controllers/diary/steps_controller.rb

module Diary
  class StepsController < ApplicationController
    include WizardSteps
    self.wizard_class = Diary::Wizard

  private

    def step_path(step = params[:id])
      placement_diary_step_path(placement_id: params[:placement_id], id: step)
    end

    def wizard_store_key
      :diary
    end

    def wizard_context
      {
        "placement_id" => params[:placement_id],
      }
    end

    def set_page_title
      @page_title = "#{@current_step.title.downcase} step"
    end
  end
end
```

In our routes:
```
resources :placements, only: :create do
    resources :diary_entries,
              only: %i[index show] do
    end
    namespace :diary do
      resources :steps,
                only: %i[index show update] do
        collection do
          get :completed
        end
      end
    end
  end
```

The placement_id is now available in `@context["placement_id"]` in wizard.rb
```
# app/models/diary/wizard.rb

module Diary
  class Wizard < ::Wizard::Base
    self.steps = [
      Steps::SelectEvent,
      Steps::Note,
      Steps::ReviewAnswers,
    ].freeze

  private

    def do_complete
      DiaryEntry.create!(
        placement_id: @context["placement_id"],
        event: @store.data["event"],
        note: @store.data["entry"],
      )
    end
  end
end
```

## Skipping Steps

The order of the steps are linear however it is possible to create a branching flow by conditionally skipping any number of steps. Steps have a default `skipped?` status of false. This can be altered by defining `skipped?` in the individual step on some condition, ususally dependent on the contents of the `@store` hash derived from previous steps, e.g.
```
def skipped?
  result = @store["some condition here is true"]

  result
end
```

A step with a `skipped?` status of true will not be shown in the form flow. In this manner it is possible to build quite complex branching forms, although the conditional logic can become convoluted!

## Accessing the store data

The `store` is a reflection of part of the session data, and can be accessed by placing a `<% byebug %>` in any step view. The session key is set from the `wizard_store_key` defined in relevent `steps_controller.rb`, e.g.
```
#app/controllers/children_creation/steps_controller.rb

module ChildrenCreation
  class StepsController < ApplicationController
    include WizardSteps
    self.wizard_class = ChildrenCreation::Wizard

  private

    def step_path(step = params[:id])
      children_creation_step_path(step)
    end

    def wizard_store_key
      :children_creation # KEY DEFINED HERE
    end

    def on_complete(child)
      redirect_to(new_child_placement_need_path(child.id))
    end
  end
end
```

With `byebug` activated in a step view, in the console all data collected up to that view will be available:

```
(byebug) session[:children_creation]
{"first_name"=>"joe", "last_name"=>"bloggs", "date_of_birth"=>"2000-01-01"}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/goodviber/wizard_steps.


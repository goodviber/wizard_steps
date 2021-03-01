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

Firstly, there is a pre-requisite of knowing what a multi-step form is if you don't already. A great resource is [this rails cast](http://railscasts.com/episodes/217-multistep-forms).

The gem is fits a typical MVC style (model-view-controller)

## Model

List your steps in a wizard.rb file, located at the base of your multi-step folder. Take the following file structure below as an example for a model to create a user:

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

The private method, do_complete, is what will be called **once the form has been submitted fully, ie when all the steps are complete**, in this example we are creating a User instance in the database. Note how @store is accessed.

In this example, our multi step form is for the User model, so we require various attributes in each step, such as Name, date of birth and Gender, store it, review the answers, and if all is good, we submit it.

Wait, but what does each step look like? Similarly to the above, it follows a modular pattern. Take the below as an example.

```
# app/models/user_creation/steps/name.rb

module UserCreation
  module Steps
    class Name < WizardSteps::Step

      attribute :first_name, :string
      attribute :last_name, :string

      validates :first_name, :last_name
      presence: true

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
# models/user_creation/steps/_date_of_birth.rb

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

## Context - TODO

## Skipping Steps

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/wizard_steps.


# WizardSteps

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/wizard_steps`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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

TODO: Write usage instructions here

## Here are some instructions in how to create multi-step forms with the Wizard Steps gem

Firstly, there is a pre-requisite of knowing what a multi-step form is if you dont already. A great resource is [this rails cast](http://railscasts.com/episodes/217-multistep-forms).

To use this gem, you will need to register your steps in a wizard.rb file, located at the base of your multi step folder. Take the following file structure below as an example for a model to create a user

```
|models
|__user_creation
|  |__steps
|  |  |__register_name.rb
|  |  |__register_age.rb
|  |  |__register_gender.rb
|  |  |__review_answers.rb
|  |__wizard.rb  <--- register your steps here
```
For the above example with four steps and a User class, lets have a look at what the wizard.rb could look like:

```
# app/models/user_creation/wizard.rb

module UserCreation
  class Wizard < WizardSteps::Base
    self.steps = [
      Steps::RegisterName,
      Steps::RegisterAge,
      Steps::RegisterGender,
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

Cool. You create a module to wrap the multi step form. Inside this module, create a new wizard which derives from WizardSteps::Base, and register the steps you plan on using. These steps should reflect what you have in your views and in the steps folder in the current directory.

The private method, do_complete, is what will be called **once the form has been submitted fully, ie when all the steps are complete**, and is what will be written into the db.

In this example, our multi step form is for the User model, so we ask various attributes in each step, such as Name, Age and Gender, store it, review the answers, and if all is good, we submit it.

Wait, but what does each step look like? Similarly to the above, it follows a modular pattern. Take the below as an example.

```
# app/models/steps/register_name.rb

module UserCreation
  module Steps
    class RegisterName < WizardSteps::Step
      include ActiveRecord::AttributeAssignment #TODO talk about dates

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

I wont dive into this too deeply, but as you can see its similar to the above. Wrap your modules up, and derive the step name (`RegisterName`) from `WizardSteps::Step`. Validate the fields you wish to add to the store.

Your review answers can look something like this:

```
require 'wizard_steps/step'

module UserCreation
  module Steps
    class ReviewAnswers < WizardSteps::Step
      def answers_by_step
        @answers_by_step ||= @wizard.reviewable_answers_by_step
      end
    end
  end
end

```

Lets move onto the controller.

Your controller layour should be something like the following:

```
|controllers
|__user_creation
|  |__steps_controller.rb
```

Yep, its that simple.

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

    def on_complete(child)
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
|  |__ _register_name.html.erb
|  |__ _register_age.html.erb
|  |__ _register_gender.html.erb
|  |__ _review_answers.html.erb
|  |__show.html.erb
```

```
# app/views/user_creation/_register_name.html.erb
<%= f.govuk_fieldset legend: { text: "Name" } do %>
  <%= f.govuk_text_field :first_name, label: { text: 'First name' } %>
  <%= f.govuk_text_field :last_name %>
<% end %>
```

```
# app/views/user_creation/show.html.erb
<%= render "form", current_step: current_step, wizard: wizard %>
```

```
# app/views/user_creation/show.html.erb
<%= render "form", current_step: current_step, wizard: wizard %>
```

And finally, in your routes

```
namespace :children_creation do
  resources :steps, only: %i[show update]
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/wizard_steps.


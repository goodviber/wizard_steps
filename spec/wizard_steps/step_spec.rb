require "spec_helper"
require "wizard_steps/step"

RSpec.describe WizardSteps::Step do
  include_context "wizard store"

  class FirstStep < WizardSteps::Step
    attribute :name
    attribute :age, :integer
    validates :name, presence: true
  end

  let(:attributes) { {} }
  subject { FirstStep.new nil, wizardstore, attributes }

  describe ".key" do
    it { expect(described_class.key).to eql "step" }
    it { expect(FirstStep.key).to eql "first_step" }
  end

  describe ".title" do
    it { expect(described_class.title).to eql "Step" }
    it { expect(FirstStep.title).to eql "First step" }
  end

  describe ".contains_personal_details?" do
    it { expect(described_class).to_not be_contains_personal_details }
    it { expect(FirstStep).to_not be_contains_personal_details }
  end

  describe ".new" do
    let(:attributes) { { age: "20" } }
    it { is_expected.to be_instance_of FirstStep }
    it { is_expected.to have_attributes key: "first_step" }
    it { is_expected.to have_attributes id: "first_step" }
    it { is_expected.to have_attributes persisted?: true }
    it { is_expected.to have_attributes name: "Joe" }
    it { is_expected.to have_attributes age: 20 }
    it { is_expected.to have_attributes skipped?: false }
  end

  describe "#can_proceed" do
    it { expect(subject).to be_can_proceed }
  end

  describe "#save!" do
    let(:backingstore) { {} }

    context "when valid" do
      let(:attributes) { { name: "Jane" } }
      let!(:result) { subject.save! }

      it { expect(result).to be true }
      it { expect(wizardstore[:name]).to eql "Jane" }
    end

    context "when invalid" do
      let(:attributes) { { age: 30 } }
      let!(:result) { subject.save! }

      it { expect(result).to be false }
      it { is_expected.to have_attributes errors: hash_including(:name) }
    end
  end

  describe "#reviewable_answers" do
    let(:backingstore) { { "name" => "Joe" } }
    let(:instance) { FirstStep.new nil, wizardstore, age: 35 }
    subject { instance.reviewable_answers }
    it { is_expected.to include "name" => "Joe" }
    it { is_expected.to include "age" => 35 }
  end

  describe "#export" do
    let(:backingstore) { { "name" => "Joe" } }
    let(:instance) { FirstStep.new nil, wizardstore, age: 35 }
    subject { instance.export }
    it { is_expected.to include "name" => "Joe" }
    it { is_expected.to include "age" => nil } # should only export persisted data
  end
end

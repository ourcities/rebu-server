require 'rails_helper'

RSpec.describe WidgetPolicy do
  context "for a visitor" do
    subject { described_class.new(nil, Widget.make!) }
    it { should allow(:index) }
    it { should allow(:show) }
    it { should_not allow(:create) }
    it { should_not allow(:new) }
    it { should_not allow(:update) }
    it { should_not allow(:edit) }
    it { should_not allow(:destroy) }
    it "should have complete scope" do
      expect(subject.scope).to eq Widget
    end
    it "should return empty permitted attributes" do
      expect(subject.permitted_attributes).to eq []
    end
  end

  context "for a non-owner user" do
    subject { described_class.new(User.make!, Widget.make!) }
    it { should allow(:index) }
    it { should allow(:show) }
    it { should allow(:create) }
    it { should allow(:new) }
    it { should_not allow(:update) }
    it { should_not allow(:edit) }
    it { should_not allow(:destroy) }
    it "should have complete scope" do
      expect(subject.scope).to eq Widget
    end
    it "should return permitted attributes" do
      expect(subject.permitted_attributes).to eq [:kind, settings: [:content, :button_text]]
    end
  end

  context "for the owner" do
    let(:user) { User.make! }
    let(:mobilization) { Mobilization.make! user: user }
    let(:block) { Block.make! mobilization: mobilization }
    subject { described_class.new(user, Widget.make!(block: block)) }
    it { should allow(:index) }
    it { should allow(:show) }
    it { should allow(:create) }
    it { should allow(:new) }
    it { should allow(:update) }
    it { should allow(:edit) }
    it { should allow(:destroy) }
    it "should have complete scope" do
      expect(subject.scope).to eq Widget
    end
    it "should return permitted attributes" do
      expect(subject.permitted_attributes).to eq [:kind, settings: [:content, :button_text]]
    end
  end
end

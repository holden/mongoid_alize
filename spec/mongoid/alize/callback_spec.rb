require 'spec_helper'

class Mongoid::Alize::SpecCallback < Mongoid::Alize::Callback
  def attach
    klass.class_eval do
      def denormalize_spec_person
      end
    end
  end

  def direction
    "spec"
  end
end

describe Mongoid::Alize::Callback do
  def klass
    Mongoid::Alize::SpecCallback
  end

  def args
    [Head, :person, [:name, :created_at]]
  end

  def new_callback
    klass.new(*args)
  end

  describe "initialize" do
    it "should assign class attributes" do
      callback = new_callback
      callback.klass.should == Head
      callback.relation.should == :person
      callback.inverse_klass = Person
      callback.inverse_relation = :head
      callback.fields.should == [:name, :created_at]
    end

    it "should not set inverses for polymorphic associations" do
      callback = klass.new(Head, :nearest, [:size])
      callback.inverse_relation.should be_nil
      callback.inverse_klass.should be_nil
    end
  end

  describe "with callback" do
    before do
      @callback = new_callback
    end

    describe "#alias_callback" do
      it "should alias the callback on the klass" do
        mock(@callback.klass).alias_method("denormalize_spec_person", "_denormalize_spec_person")
        @callback.send(:alias_callback)
      end

      it "should not alias the callback if it's already set" do
        @callback.send(:attach)
        dont_allow(@callback.klass).alias_method
        @callback.send(:alias_callback)
      end
    end
  end

  describe "name helpers" do
    before do
      @callback = new_callback
    end

    it "should have a callback name" do
      @callback.callback_name.should == "_denormalize_spec_person"
    end

    it "should have aliased callback name" do
      @callback.aliased_callback_name.should == "denormalize_spec_person"
    end

    it "should add _fields to the callback name" do
      @callback.fields_method_name.should == "_denormalize_spec_person_fields"
    end
  end

  describe "define fields method" do
    def define_fields_method
      @callback.send(:define_fields_method)
    end

    describe "when fields is an array" do
      before do
        @callback = new_callback
      end

      it "should return the fields w/ to_s applied" do
        define_fields_method
        @head = Head.new
        @head.send("_denormalize_spec_person_fields", nil).should == ["name", "created_at"]
      end
    end

    describe "when fields is a proc" do
      before do
        @callback = klass.new(Head, :person, lambda { |inverse| [:name, :created_at] })
      end

      it "should return the fields w/ to_s applied" do
        define_fields_method
        @head = Head.new
        @head.send("_denormalize_spec_person_fields", Person.new).should == ["name", "created_at"]
      end
    end
  end
end


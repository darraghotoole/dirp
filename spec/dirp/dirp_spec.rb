require_relative "../../lib/dirp"

class NoArgsClass
end

class ClassWithArgs
	attr_reader :no_args_class
	def initialize(no_args_class)
		@no_args_class = no_args_class
	end
end


class ClassWithGrandChild
	attr_reader :class_with_args, :no_args_class
	def initialize(class_with_args, no_args_class)
		@class_with_args = class_with_args
		@no_args_class = no_args_class
	end
end

module Dirp
	describe Registry do
		let(:registry) {Registry.new}

		describe "binding classes" do
			it "binds reference to class" do
				registry.bind(:foo, String)
				expect(registry.get_class(:foo)).to eq(String)
			end

			it "raises error when binding same reference twice" do
				registry.bind(:foo, String)
				expect{registry.bind(:foo, Array)}.to raise_error(AlreadyBoundError)
			end
		end

		describe "binding instances" do
			it "bind to instance" do
				registry.bind_instance(:foo, "asdas")
				expect(registry.get(:foo)).to eq("asdas")
			end


			it "populates candidate class" do
				registry.bind_instance(:foo, "asdas")
				expect(registry.get_class(:foo)).to eq(String)
			end

			it "raises error when binding same reference twice" do
				registry.bind_instance(:foo, "foo")
				expect{registry.bind_instance(:foo, "bar")}.to raise_error(AlreadyBoundError)
			end
		end

		describe "building candidates" do


			it "can build classes with no-arg constructors" do
				registry.bind(:no_args_class, NoArgsClass)
				expect(registry.get(:no_args_class)).to be_a(NoArgsClass)
			end


			it "can build classes with constructor args" do
				registry.bind(:no_args_class, NoArgsClass)
				registry.bind(:class_with_args, ClassWithArgs)
				
				instance = registry.get(:class_with_args)
				expect(instance).to be_a(ClassWithArgs)
				expect(instance.no_args_class).to be_a(NoArgsClass)
			end

			it "populates recursively and reuses instances" do
				no_args_instance = NoArgsClass.new
				registry.bind_instance(:no_args_class, no_args_instance)
				registry.bind(:class_with_args, ClassWithArgs)
				registry.bind(:class_with_grand_child, ClassWithGrandChild)

				instance = registry.get(:class_with_grand_child)
				expect(instance).to be_a(ClassWithGrandChild)
				expect(instance.no_args_class).to eq(no_args_instance)
				expect(instance.class_with_args).to be_a(ClassWithArgs)
				expect(instance.class_with_args.no_args_class).to eq(no_args_instance)
			end

			class A
				def initialize(b)
				end
			end

			class B
				def initialize(a)
				end
			end

			it "raises error if a circular dependency is present" do
				registry.bind(:a, A)
				registry.bind(:b, B)
				expect{registry.get(:a)}.to raise_error(CircularDependencyError)
			end
		end

		it "can create alias references to existing bindings" do
			registry.bind_instance(:foo, "foobar")
			registry.bind_alias(:bar, :foo)
			expect(registry.get(:bar)).to eq("foobar")
		end

		it "raises not bound error when a reference is not bound" do
			expect{registry.get_class(:im_not_bound)}.to raise_error(NotBoundError)
			expect{registry.get(:im_not_bound)}.to raise_error(NotBoundError)
		end

		describe "#create" do
			it "should create a registry" do
				registry = Registry.create do
					bind(:no_args_class, NoArgsClass)
					bind_instance(:foobar, "Foobar")
					bind_alias(:fizzbuzz, :foobar)
				end

				expect(registry.get(:foobar)).to eq("Foobar")
				expect(registry.get(:fizzbuzz)).to eq("Foobar")
				expect(registry.get(:no_args_class)).to be_a(NoArgsClass)
			end
		end
	end
end
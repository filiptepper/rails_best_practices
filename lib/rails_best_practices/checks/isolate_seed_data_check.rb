# encoding: utf-8
require 'rails_best_practices/checks/check'

module RailsBestPractices
  module Checks
    # Make sure not to insert data in migration, move them to seed file.
    #
    # See the best practice details here http://rails-bestpractices.com/posts/20-isolating-seed-data.
    #
    # Implementation:
    #
    # Prepare process:
    #   none
    #
    # Review process:
    #   1. check all local assignment and instance assignment nodes,
    #   if the right value is a call node with message :new,
    #   then remember their left value as new variables.
    #
    #   2. check all call nodes,
    #   if the message is :create or :create!,
    #   then it should be isolated to db seed.
    #   if the message is :save or :save!,
    #   and the subject is included in new variables,
    #   then it should be isolated to db seed.
    class IsolateSeedDataCheck < Check
      def url
        "http://rails-bestpractices.com/posts/20-isolating-seed-data"
      end

      def interesting_review_nodes
        [:call, :lasgn, :iasgn]
      end

      def interesting_review_files
        MIGRATION_FILES
      end

      def initialize
        super
        @new_variables = []
      end

      # check local assignment node in review process.
      #
      # if the right value of the node is a call node with :new message,
      # then remember it as new variables (@new_variables).
      def review_start_lasgn(node)
        remember_new_variable(node)
      end

      # check instance assignment node in review process.
      #
      # if the right value of the node is a call node with :new message,
      # then remember it as new variables (@new_variables).
      def review_start_iasgn(node)
        remember_new_variable(node)
      end

      # check the call node in review process.
      #
      # if the message of the call node is :create or :create!,
      # then you should isolate it to seed data.
      #
      # if the message of the call node is :save or :save!,
      # and the subject of the call node is included in @new_variables,
      # then you should isolate it to seed data.
      def review_start_call(node)
        if [:create, :create!].include? node.message
          add_error("isolate seed data")
        elsif [:save, :save!].include? node.message
          add_error("isolate seed data") if new_record?(node)
        end
      end

      private
        # check local assignment or instance assignment node,
        # if the right vavlue is a call node with message :new,
        # then remember the left value as new variable.
        #
        # if the local variable node is
        #
        #     s(:lasgn, :role, s(:call, s(:const, :Role), :new, s(:arglist, s(:hash, s(:lit, :name), s(:lvar, :name)))))
        #
        # then the new variables (@new_variables) is
        #
        #     ["role"]
        def remember_new_variable(node)
          right_value = node.right_value
          if :call == right_value.node_type && :new == right_value.message
            @new_variables << node.left_value.to_s
          end
        end

        # see if the subject of the call node is included in the @new_varaibles.
        def new_record?(node)
          @new_variables.include? node.subject.to_s
        end
    end
  end
end

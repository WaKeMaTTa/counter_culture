module CounterCulture
  module ActiveRecord
    module Associations
      module HasManyAssociation

        private

        # Returns the number of records in this collection.
        #
        # If the association has a counter cache it gets that value. Otherwise
        # it will attempt to do a count via SQL, bounded to <tt>:limit</tt> if
        # there's one. Some configuration options like :group make it impossible
        # to do an SQL count, in those cases the array count will be used.
        #
        # That does not depend on whether the collection has already been loaded
        # or not. The +size+ method is the one that takes the loaded flag into
        # account and delegates to +count_records+ if needed.
        #
        # If the collection is empty the target is set to an empty array and
        # the loaded flag is set to true as well.
        #
        # Overwrite method of `ActiveRecord::Associations:HasManyAssociation`
        def count_records
          count = if has_cached_counter?
            owner._read_attribute cached_counter_attribute_name
          elsif has_cached_counter_culture?
            owner._read_attribute cached_counter_attribute_name
          else
            scope.count
          end

          # If there's nothing in the database and @target has no new records
          # we are certain the current target is an empty array. This is a
          # documented side-effect of the method that may avoid an extra SELECT.
          @target ||= [] and loaded! if count == 0

          [association_scope.limit_value, count].compact.min
        end

        # Method inspired from `ActiveRecord::Associations:HasManyAssociation#has_cached_counter?`
        def has_cached_counter_culture?(reflection = reflection())
          if (inverse = inverse_which_updates_counter_culture_cache(reflection))
            owner.attribute_present?(cached_counter_culture_attribute_name(inverse))
          end
        end

        # Method inspired from `ActiveRecord::Associations:HasManyAssociation#inverse_which_updates_counter_cache`
        def inverse_which_updates_counter_culture_cache(reflection = reflection())
          reflection.klass._reflections.values.find { |inverse_reflection|
            inverse_reflection.belongs_to? &&
            counter_culture_counter(inverse_reflection)
          }
        end

        # Method inspired from `ActiveRecord::Associations:HasManyAssociation#cached_counter_attribute_name`
        def cached_counter_culture_attribute_name(inverse_reflection)
          counter_culture_counter(inverse_reflection).counter_cache_name
        end

        # Overwrite method of `ActiveRecord::Associations:HasManyAssociation`
        def cached_counter_attribute_name(reflection = reflection())
          if reflection.options[:counter_cache]
            reflection.options[:counter_cache].to_s
          elsif (inverse = inverse_which_updates_counter_culture_cache(reflection)) &&
                (counter_cache_name = cached_counter_culture_attribute_name(inverse))
            counter_cache_name
          else
            "#{reflection.name}_count"
          end
        end

        # Helper method to get the `CounterCulture::Counter` instance
        def counter_culture_counter(inverse_reflection)
          reflection.klass.after_commit_counter_cache.find { |counter|
            counter.model == reflection.klass
          }
        end

      end
    end
  end
end

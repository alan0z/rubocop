# frozen_string_literal: true

# rubocop:disable Lint/RedundantCopDisableDirective

module RuboCop
  module Cop
    module Style
      # Detects comments to enable/disable RuboCop.
      # This is useful if want to make sure that every RuboCop error gets fixed
      # and not quickly disabled with a comment.
      #
      # Specific cops can be allowed with the `AllowedCops` configuration. Note that
      # if this configuration is set, `rubocop:disable all` is still disallowed.
      #
      # @example
      #   # bad
      #   # rubocop:disable Metrics/AbcSize
      #   def foo
      #   end
      #   # rubocop:enable Metrics/AbcSize
      #
      #   # good
      #   def foo
      #   end
      #
      # @example AllowedCops: [Metrics/AbcSize]
      #   # good
      #   # rubocop:disable Metrics/AbcSize
      #   def foo
      #   end
      #   # rubocop:enable Metrics/AbcSize
      #
      class DisableCopsWithinSourceCodeDirective < Base
        extend AutoCorrector

        # rubocop:enable Lint/RedundantCopDisableDirective
        MSG = 'Rubocop disable/enable directives are not permitted.'
        MSG_FOR_COPS = 'Rubocop disable/enable directives for %<cops>s are not permitted.'

        def on_new_investigation
          processed_source.comments.each do |comment|
            directive_cops = directive_cops(comment)
            disallowed_cops = directive_cops - allowed_cops

            next unless disallowed_cops.any?

            register_offense(comment, directive_cops, disallowed_cops)
          end
        end

        private

        def register_offense(comment, directive_cops, disallowed_cops)
          message = if any_cops_allowed?
                      format(MSG_FOR_COPS, cops: "`#{disallowed_cops.join('`, `')}`")
                    else
                      MSG
                    end

          add_offense(comment, message: message) do |corrector|
            replacement = ''

            if directive_cops.length != disallowed_cops.length
              replacement = comment.text.sub(/#{Regexp.union(disallowed_cops)},?\s*/, '')
                                   .sub(/,\s*$/, '')
            end

            corrector.replace(comment, replacement)
          end
        end

        def directive_cops(comment)
          match = CommentConfig::COMMENT_DIRECTIVE_REGEXP.match(comment.text)
          match && match[2] ? match[2].split(',').map(&:strip) : []
        end

        def allowed_cops
          Array(cop_config['AllowedCops'])
        end

        def any_cops_allowed?
          allowed_cops.any?
        end
      end
    end
  end
end

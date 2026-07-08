# frozen_string_literal: true

module Forms
  # A tag field WITHOUT its own reactive root — for use inside a Forms::Live form,
  # which is itself the reactive root and carries the tag wire attributes
  # (data-reactive-tags-field / data-reactive-filter-input, hoisted by
  # Forms::Live#form_attributes). Emitting no nested root means the hidden tags
  # field's nearest reactive-root ancestor is the <form>, so the outer form OWNS
  # it and live :validate collects it (phlex-reactive #ownsField, issue #15).
  #
  # Reuses Forms::TagField's #body verbatim (chip/template/suggestion markup), so
  # the two never drift; it only drops the root <div> wrapper.
  #
  # Autoloaded only when Phlex::Reactive is present (it inherits from a
  # ClientBindings-including class).
  class RootlessTagField < Forms::TagField
    def view_template
      # No reactive_root wrapper: a bare container that groups the body. The tag
      # attrs live on the ancestor <form>, not here.
      div(class: root_classes) { body }
    end
  end
end

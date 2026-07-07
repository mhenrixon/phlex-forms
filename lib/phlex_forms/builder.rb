# frozen_string_literal: true

module PhlexForms
  # The shared form-builder surface, included by Forms::Form, Forms::Field, and
  # Forms::FieldsForBuilder so the three no longer copy-paste the API three times.
  #
  # Two layers:
  #
  #   * The Control-first primary verb `field` — renders label + input +
  #     error/hint in one call, inferring the input type and the `required` flag
  #     from the model.
  #
  #   * Lower-level escape hatches (`Input`, `Select`, `Textarea`, `Checkbox`,
  #     `Toggle`, `FileInput`, `Hidden`, `Label`, `Control`, `submit`) with the
  #     same signatures they had before extraction, for when a caller needs full
  #     control (custom Stimulus wiring, bespoke layout, ...).
  #
  # Hosts mix this in and provide: `render`, `model`, `scope`, `errors`, and a
  # `field(name)`-style `field_object` that returns a Forms::Field for a name.
  module Builder
    # Positional symbols that name an input type (so `f.Input(:x, :email)` works).
    INPUT_TYPE_MODIFIERS = %i[
      text email password tel url search number date time datetime
      color range file hidden month week
    ].freeze

    # Attribute-name -> input type inference. One canonical map (previously
    # duplicated and divergent across Form and Field).
    INPUT_TYPE_INFERENCE = {
      email: :email,
      password: :password, password_confirmation: :password,
      current_password: :password, new_password: :password,
      new_password_confirmation: :password,
      phone: :tel, telephone: :tel, tel: :tel, mobile: :tel,
      url: :url, website: :url, homepage: :url,
      search: :search, query: :search,
      date: :date, birthday: :date, birthdate: :date, born_on: :date,
      started_at: :date, ended_at: :date,
      time: :time,
      datetime: :datetime, timestamp: :datetime,
      color: :color, colour: :color
    }.freeze

    # ------------------------------------------------------------------
    # Control-first primary API
    # ------------------------------------------------------------------

    # Render a complete field: label + control-wrapped input + error/hint.
    #
    #   f.field :email                          # type=email, label auto, required inferred
    #   f.field :role, as: :select, choices: roles
    #   f.field :bio, as: :textarea, rows: 6
    #   f.field :accept, as: :toggle
    #   f.field :name, :primary, label: "Full name", hint: "As on your ID"
    #
    # Options:
    #   label:    label text (defaults to the model's humanized attribute name;
    #             pass false to omit the label)
    #   hint:     help text shown when there is no error
    #   as:       override the rendered control (:select, :textarea, :toggle,
    #             :checkbox, :file, :hidden, and text-like types)
    #   required: force the required flag (otherwise inferred from validations)
    #   choices:  choices for :select
    # Remaining positional modifiers/keywords pass through to the inner input.
    def field(name, *modifiers, label: nil, hint: nil, as: nil, required: nil,
              choices: nil, **options)
      fo = field_object(name)
      req = required.nil? ? fo.required? : required
      label_text = label == false ? nil : (label || fo.field_label)

      render fo.control(label: label_text, hint:, required: req) do
        render_field_input(fo, name, as, modifiers, choices:, required: req, **options)
      end
    end

    # ------------------------------------------------------------------
    # Escape-hatch component API (stable signatures)
    # ------------------------------------------------------------------

    def Input(name, *modifiers, **)
      type = resolve_input_type(name, modifiers)
      type = :"datetime-local" if type == :datetime
      remaining = modifiers - INPUT_TYPE_MODIFIERS
      render field_object(name).input(*remaining, type:, **)
    end

    def Select(name, *modifiers, choices: nil, **)
      render field_object(name).choices_select(choices, *modifiers, **)
    end

    def Textarea(name, *modifiers, **)
      render field_object(name).textarea(*modifiers, **)
    end

    def Checkbox(name, *modifiers, **)
      render field_object(name).checkbox(*modifiers, **)
    end

    def Radio(name, value, *modifiers, **)
      render field_object(name).radio(value, *modifiers, **)
    end

    def Toggle(name, *modifiers, **)
      render field_object(name).toggle(*modifiers, **)
    end

    def FileInput(name, *modifiers, **)
      render field_object(name).file(*modifiers, **)
    end

    def Hidden(name, **)
      render field_object(name).hidden(**)
    end

    def Label(name, text = nil, *modifiers, **, &)
      render field_object(name).label(text, *modifiers, **, &)
    end

    def Control(name, **, &)
      render field_object(name).control(**, &)
    end

    private

    # Dispatch the inner input for `field` based on `as:` / inferred type.
    def render_field_input(fo, name, as, modifiers, choices:, required:, **)
      kind = as || resolve_input_type(name, modifiers)
      case kind
      when :select   then render fo.choices_select(choices, *modifiers, required:, **)
      when :textarea then render fo.textarea(*modifiers, required:, **)
      when :toggle   then render fo.toggle(*modifiers, required:, **)
      when :checkbox then render fo.checkbox(*modifiers, required:, **)
      when :file     then render fo.file(*modifiers, required:, **)
      when :hidden   then render fo.hidden(**)
      else
        type = kind == :datetime ? :"datetime-local" : kind
        render fo.input(*(modifiers - INPUT_TYPE_MODIFIERS), type:, required:, **)
      end
    end

    def resolve_input_type(name, modifiers)
      explicit = modifiers.find { |m| INPUT_TYPE_MODIFIERS.include?(m) }
      explicit || INPUT_TYPE_INFERENCE[name.to_sym] || :text
    end
  end
end

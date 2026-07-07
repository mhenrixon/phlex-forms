# frozen_string_literal: true

module PhlexForms
  # The shared form-builder surface, included by Forms::Form and
  # Forms::FieldsForBuilder so the two no longer copy-paste the API.
  #
  # Two layers:
  #
  #   * The Control-first primary verb `field` — renders label + input +
  #     error/hint in one call, inferring the input type and the `required` flag
  #     from the model (structure, column types, validators — see
  #     PhlexForms::Inference) with the attribute-name map as tiebreaker.
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
    #   f.field :notify                         # boolean column -> toggle
    #   f.field :role                           # AR enum -> select, humanized
    #   f.field :country                        # belongs_to -> select over the association
    #   f.field :bio, as: :textarea, rows: 6    # explicit as: always wins
    #   f.field :name, :primary, label: "Full name", hint: "As on your ID"
    #
    # Options:
    #   label:    label text (defaults to the model's humanized attribute name;
    #             pass false to omit the label)
    #   hint:     help text shown when there is no error
    #   as:       override the rendered control (:select, :textarea, :toggle,
    #             :checkbox, :file, :hidden, :rich_textarea, and text-like types)
    #   required: force the required flag (otherwise inferred from validations)
    #   choices:  choices for :select (implies as: :select when given)
    # Remaining positional modifiers/keywords pass through to the inner input.
    def field(name, *modifiers, label: nil, hint: nil, as: nil, required: nil,
              choices: nil, **options)
      modifiers = default_field_variants + modifiers
      inferred = PhlexForms::Inference.resolve(model:, name:, as:, modifiers:, choices:)
      # error_name: for a rewritten field (:country -> :country_id) errors still
      # live on the association name.
      fo = field_object(inferred.name, error_name: name)
      req = required.nil? ? (fo.required? || inferred.required == true) : required
      label_text = label == false ? nil : (label || inferred.label || fo.field_label)
      options = inferred.attributes.merge(options)
      if inferred.multiple
        options[:multiple] = true unless options.key?(:multiple)
        options[:name] ||= "#{fo.field_name}[]"
      end
      options = fo.apply_validations(options)
      choices ||= materialize_choices(inferred.choices)

      render fo.control(label: label_text, hint:, required: req) do
        render_field_input(fo, inferred.name, inferred.as, modifiers, choices:, required: req, **options)
      end
    end

    # ------------------------------------------------------------------
    # Layout helpers
    # ------------------------------------------------------------------

    # Side-by-side fields in a responsive grid (stacked on mobile).
    #   f.row { f.field :first_name; f.field :last_name }
    def row(columns: 2, **, &)
      render theme[:row].new(columns:, **), &
    end

    # A fieldset with a legend for sectioning related fields.
    #   f.group(legend: "Address") { f.field :street }
    def group(legend: nil, **, &)
      render theme[:group].new(legend:, **), &
    end

    # ------------------------------------------------------------------
    # Escape-hatch component API (stable signatures)
    # ------------------------------------------------------------------

    def Input(name, *modifiers, **options)
      fo = field_object(name)
      type = resolve_input_type(name, modifiers)
      type = :"datetime-local" if type == :datetime
      remaining = modifiers - INPUT_TYPE_MODIFIERS
      render fo.input(*remaining, type:, **fo.apply_validations(options))
    end

    def Select(name, *modifiers, choices: nil, **options)
      fo = field_object(name)
      render fo.choices_select(choices, *modifiers, **fo.apply_validations(options))
    end

    def Textarea(name, *modifiers, **options)
      fo = field_object(name)
      render fo.textarea(*modifiers, **fo.apply_validations(options))
    end

    def Checkbox(name, *modifiers, **options)
      fo = field_object(name)
      render fo.checkbox(*modifiers, **fo.apply_validations(options))
    end

    def Radio(name, value, *modifiers, **)
      render field_object(name).radio(value, *modifiers, **)
    end

    def Toggle(name, *modifiers, **options)
      fo = field_object(name)
      render fo.toggle(*modifiers, **fo.apply_validations(options))
    end

    def FileInput(name, *modifiers, **options)
      fo = field_object(name)
      render fo.file(*modifiers, **fo.apply_validations(options))
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
      when :select        then render fo.choices_select(choices, *modifiers, required:, **)
      when :textarea      then render fo.textarea(*modifiers, required:, **)
      when :toggle        then render fo.toggle(*modifiers, required:, **)
      when :checkbox      then render fo.checkbox(*modifiers, required:, **)
      when :file          then render fo.file(*modifiers, required:, **)
      when :hidden        then render fo.hidden(**)
      when :rich_textarea then render fo.rich_textarea(*modifiers, **)
      else
        type = kind == :datetime ? :"datetime-local" : kind
        render fo.input(*(modifiers - INPUT_TYPE_MODIFIERS), type:, required:, **)
      end
    end

    def materialize_choices(choices)
      choices.respond_to?(:call) ? choices.call : choices
    end

    def resolve_input_type(name, modifiers)
      explicit = modifiers.find { |m| INPUT_TYPE_MODIFIERS.include?(m) }
      explicit || INPUT_TYPE_INFERENCE[name.to_sym] || :text
    end
  end
end

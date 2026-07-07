// Bundled validation messages for phlex-forms, keyed by locale then by the
// `js.forms.validations.*` dotted scope. Combined from the Cosmos (en/sv/de) and
// getzazu/app (en/fr/af) locale sets; sv/de start from English and are refined
// by the locallingo translation pass. Host apps override via
// window.PhlexForms.messages.
export const messages = {
  en: {
    js: {
      forms: {
        validations: {
          acceptance: { accepted: "must be accepted" },
          confirmation: { confirmation: "doesn't match confirmation" },
          exclusion: { exclusion: "is reserved" },
          format: { invalid: "is invalid" },
          inclusion: { inclusion: "is not included in the list" },
          length: {
            too_long: "is too long (maximum is %{count} characters)",
            too_short: "is too short (minimum is %{count} characters)",
            wrong_length: "is the wrong length (should be %{count} characters)",
          },
          numericality: {
            equal_to: "must be equal to %{count}",
            even: "must be even",
            greater_than: "must be greater than %{count}",
            greater_than_or_equal_to: "must be greater than or equal to %{count}",
            less_than: "must be less than %{count}",
            less_than_or_equal_to: "must be less than or equal to %{count}",
            not_a_number: "is not a number",
            not_an_integer: "must be an integer",
            odd: "must be odd",
            other_than: "must be other than %{count}",
          },
          presence: { blank: "can't be blank" },
        },
      },
    },
  },
  fr: {
    js: {
      forms: {
        validations: {
          acceptance: { accepted: "doit être accepté(e)" },
          confirmation: { confirmation: "ne concorde pas avec la confirmation" },
          exclusion: { exclusion: "n'est pas disponible" },
          format: { invalid: "n'est pas valide" },
          inclusion: { inclusion: "n'est pas inclus(e) dans la liste" },
          length: {
            too_long: "est trop long (pas plus de %{count} caractères)",
            too_short: "est trop court (au moins %{count} caractères)",
            wrong_length: "ne fait pas la bonne longueur (doit comporter %{count} caractères)",
          },
          numericality: {
            equal_to: "doit être égal à %{count}",
            even: "doit être pair",
            greater_than: "doit être supérieur à %{count}",
            greater_than_or_equal_to: "doit être supérieur ou égal à %{count}",
            less_than: "doit être inférieur à %{count}",
            less_than_or_equal_to: "doit être inférieur ou égal à %{count}",
            not_a_number: "n'est pas un nombre",
            not_an_integer: "doit être un nombre entier",
            odd: "doit être impair",
            other_than: "doit être différent de %{count}",
          },
          presence: { blank: "doit être rempli(e)" },
        },
      },
    },
  },
  af: {
    js: {
      forms: {
        validations: {
          acceptance: { accepted: "moet aanvaar word" },
          confirmation: { confirmation: "pas nie by bevestiging nie" },
          exclusion: { exclusion: "is bespreek" },
          format: { invalid: "is ongeldig" },
          inclusion: { inclusion: "is nie by die lys ingesluit nie" },
          length: {
            too_long: "is te lank (maksimum is %{count} karakters)",
            too_short: "is te kort (minimum is %{count} karakters)",
            wrong_length: "is die verkeerde lengte (moet %{count} karakters wees)",
          },
          numericality: {
            equal_to: "moet gelyk wees aan %{count}",
            even: "moet ewe wees",
            greater_than: "moet meer wees as %{count}",
            greater_than_or_equal_to: "moet meer of gelykstaande wees aan %{count}",
            less_than: "moet minder wees as %{count}",
            less_than_or_equal_to: "moet minder of gelykstaande wees aan %{count}",
            not_a_number: "is nie 'n getal nie",
            not_an_integer: "moet 'n heelgetal wees",
            odd: "moet onewe wees",
            other_than: "moet anders wees as %{count}",
          },
          presence: { blank: "mag nie leeg wees nie" },
        },
      },
    },
  },
}

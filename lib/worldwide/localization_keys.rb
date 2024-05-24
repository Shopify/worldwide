# frozen_string_literal: true

module Worldwide
  # A data class storing the keys used by a Region to refer to certain localized fields
  #
  # @example
  #   Worldwide.region(code: "CA").localization_keys.zone == "province"
  #
  #   # This indicates that localized fields should refer to the country_db.addresses.zone.province translation key
  #   # for an appropriately translated Canadian zone label.
  class LocalizationKeys
    # Initializes LocalizationKeys
    #
    # @param attributes [Hash<String, String>] field key mappings
    # @option attributes [String] :address1
    # @option attributes [String] :street_name
    # @option attributes [String] :street_number
    # @option attributes [String] :address2
    # @option attributes [String] :neighborhood
    # @option attributes [String] :city
    # @option attributes [String] :company
    # @option attributes [String] :country
    # @option attributes [String] :first_name
    # @option attributes [String] :last_name
    # @option attributes [String] :phone
    # @option attributes [String] :postal_code
    # @option attributes [String] :zone
    def initialize(attributes)
      @address2 = attributes.fetch("address2", nil)
      @street_name = attributes.fetch("street_name", nil)
      @street_number = attributes.fetch("street_number", nil)
      @address1 = attributes.fetch("address1", nil)
      @neighborhood = attributes.fetch("neighborhood", nil)
      @city = attributes.fetch("city", nil)
      @company = attributes.fetch("company", nil)
      @country = attributes.fetch("country", nil)
      @first_name = attributes.fetch("first_name", nil)
      @last_name = attributes.fetch("last_name", nil)
      @phone = attributes.fetch("phone", nil)
      @zip = attributes.fetch("zip", nil)
      @province = attributes.fetch("province", nil)

      @to_h = PUBLIC_ATTRIBUTES.map do |attr|
        [attr.to_s, instance_variable_get(:"@#{attr}")]
      end.to_h.compact.freeze
    end

    # These instance variables are exposed through attr_readers and through {to_h}
    # If you add a new attribute, you MUST add it to `PUBLIC_ATTRIBUTES` and to the documentation below
    # @!attribute [r] address1
    #   @return [String]
    # @!attribute [r] street_name
    #   @return [String]
    # @!attribute [r] street_number
    #   @return [String]
    # @!attribute [r] address2
    #   @return [String]
    # @!attribute [r] neighborhood
    #   @return [String]
    # @!attribute [r] city
    #   @return [String]
    # @!attribute [r] company
    #   @return [String]
    # @!attribute [r] country
    #   @return [String]
    # @!attribute [r] first_name
    #   @return [String]
    # @!attribute [r] last_name
    #   @return [String]
    # @!attribute [r] phone
    #   @return [String]
    # @!attribute [r] postal_code
    #   @return [String]
    # @!attribute [r] zone
    #   @return [String]
    PUBLIC_ATTRIBUTES = [
      :address1,
      :street_name,
      :street_number,
      :address2,
      :neighborhood,
      :city,
      :company,
      :country,
      :first_name,
      :last_name,
      :phone,
      :zip,
      :province,
    ]
    private_constant :PUBLIC_ATTRIBUTES
    attr_reader(*PUBLIC_ATTRIBUTES)

    # @return [Hash] a Hash representation of the data
    # @note The Hash is compacted and frozen.
    # @note All of the attributes exposed through #to_h are also exposed through readers. See the `PUBLIC_ATTRIBUTES`
    #   constant in the source code for a complete list.
    attr_reader :to_h

    # TODO, FIX
    # delegate(:[], :merge, :fetch, :dig, :keys, :key?, :slice, :with_indifferent_access, to: :to_h)
  end
end

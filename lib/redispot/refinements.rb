module Redispot
  module Refinements
    refine Object do
      def blank?
        respond_to?(:empty?) ? !!empty? : !self
      end

      def present?
        !blank?
      end

      def presence
        self if present?
      end
    end

    refine Hash do
      def symbolize_keys
        each_key.each_with_object(Hash.new) do |key, memo|
          memo[key.to_sym] = fetch(key)
        end
      end
    end
  end
end

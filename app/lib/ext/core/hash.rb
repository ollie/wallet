class Hash
  def stringify_keys
    {}.tap do |hash|
      each do |key, value|
        hash[key.to_s] = value
      end
    end
  end

  def scrub
    dup.scrub!
  end

  def scrub!
    each do |key, value|
      delete(key) if !value || value.respond_to?(:empty?) && value.empty?
    end
  end

  def except(*keys)
    dup.tap do |hash|
      keys.each { |key| hash.delete(key) }
    end
  end
end

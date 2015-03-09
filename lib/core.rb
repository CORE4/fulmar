

class ::Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2|
      if Hash === v1 && Hash === v2
        v1.merge(v2, &merger)
      else
        [:undefined, nil, :nil].include?(v2) ? v1 : v2
      end
    }
    self.merge(second, &merger)
  end
end
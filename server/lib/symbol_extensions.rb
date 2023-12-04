module SymbolExtensions

  refine Symbol do
    def call(*args, &block)
      ->(caller, *rest) { caller.send(self, *rest, *args, &block) }
    end
  end

end

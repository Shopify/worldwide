# frozen_string_literal: true

require "bigdecimal"
require "test_helper"
require "open3"
require "psych"
require "worldwide/cldr/bundled_data_test_helper"

module Worldwide
  module Cldr
    class BundledDataTest < ActiveSupport::TestCase
      include Worldwide::BundledDataTestHelper

      # Collects the keys directly under each locale of a YAML document, without building the document.
      class SegmentCollector < Psych::Handler
        attr_reader :segments

        def initialize
          super
          @frames = []
          @segments = Hash.new { |hash, locale| hash[locale] = [] }
        end

        def start_mapping(*)
          node(nil)
          @frames.push([true, nil])
        end

        def end_mapping
          @frames.pop
        end

        def start_sequence(*)
          node(nil)
          @frames.push(nil)
        end

        def end_sequence
          @frames.pop
        end

        def scalar(value, *)
          node(value)
        end

        def alias(*)
          node(nil)
        end

        private

        # Each mapping frame is [next node is a key, last key].
        def node(value)
          frame = @frames.last
          return if frame.nil?

          if frame[0]
            frame[1] = value
            @segments[@frames[0][1]] << value if @frames.size == 2
            frame[0] = false
          else
            frame[0] = true
          end
        end
      end

      test "bundled_data? is true only inside with_bundled_data" do
        assert_equal false, Worldwide::Cldr.bundled_data?

        result = Worldwide::Cldr.with_bundled_data do
          assert_equal(true, Worldwide::Cldr.bundled_data?)
          :result
        end

        assert_equal :result, result
        assert_equal false, Worldwide::Cldr.bundled_data?
      end

      test "with_bundled_data restores the enclosing state when nested and when the block raises" do
        Worldwide::Cldr.with_bundled_data do
          Worldwide::Cldr.with_bundled_data do
            assert_equal true, Worldwide::Cldr.bundled_data?
          end

          assert_equal true, Worldwide::Cldr.bundled_data?

          assert_raises(RuntimeError) do
            Worldwide::Cldr.with_bundled_data { raise "boom" }
          end

          assert_equal true, Worldwide::Cldr.bundled_data?
        end

        assert_equal false, Worldwide::Cldr.bundled_data?
      end

      test "with_bundled_data requires a block" do
        assert_raises(ArgumentError) { Worldwide::Cldr.with_bundled_data }
      end

      test "lookups inside the block ignore the host backend, and lookups outside it still read it" do
        eur = Worldwide.currency(code: "EUR")

        with_host_overrides do
          [true, false].each do |bundled|
            values = lambda do
              {
                decimal: Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de),
                inherited_decimal: Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :"de-AT"),
                symbol: eur.symbol(locale: :en),
                format_short: eur.format_short(1234.5, locale: :de),
                format_explicit: eur.format_explicit(1234.5, locale: :de),
                label: I18n.with_locale(:en) { eur.label(count: 2) },
                name: I18n.with_locale(:en) { eur.name },
                number: Worldwide::Numbers.new(locale: :fr).format(1234567.5, decimal_places: 2),
                list: Worldwide.lists.format(["a", "b"], join: :or, locale: :de),
              }
            end

            if bundled
              assert_equal(
                {
                  decimal: ",",
                  inherited_decimal: ",",
                  symbol: "€",
                  format_short: "1.234,50\u00A0€",
                  format_explicit: "1.234,50\u00A0€ EUR",
                  label: "euros",
                  name: "Euro",
                  number: "1\u202F234\u202F567,50",
                  list: "a oder b",
                },
                Worldwide::Cldr.with_bundled_data { values.call },
              )
            else
              assert_equal(
                {
                  decimal: "HOST-DECIMAL",
                  inherited_decimal: "HOST-DECIMAL",
                  symbol: "HOST-€",
                  format_short: "1.234HOST-DECIMAL50\u00A0€",
                  format_explicit: "1.234HOST-DECIMAL50\u00A0€ EUR",
                  label: "host euros",
                  name: "Host Euro",
                  number: "1_234_567,50",
                  list: "HOST a b",
                },
                values.call,
              )
            end
          end
        end
      end

      test "the rounding, grouping and sign options read bundled data inside the block" do
        eur = Worldwide.currency(code: "EUR")
        pln = Worldwide.currency(code: "PLN")
        polish = Worldwide::Numbers.new(locale: :pl)

        with_host_overrides do
          Worldwide::Cldr.with_bundled_data do
            assert_equal "1234,50", polish.format(1234.5, decimal_places: 2, grouping: :auto)
            assert_equal "12\u00A0345,50", polish.format(12345.5, decimal_places: 2, grouping: :auto)
            assert_equal "0,13\u00A0€", eur.format_short(BigDecimal("0.125"), locale: :de, rounding_mode: :half_up)
            assert_equal "0,00\u00A0€", eur.format_short(-0.004, locale: :de, sign_display: :negative)
            assert_equal(
              [
                { type: :minus_sign, value: "-" },
                { type: :number, value: "1234,50" },
                { type: :literal, value: "\u00A0" },
                { type: :currency, value: "zł" },
              ],
              pln.format_to_parts(-1234.5, locale: :pl, grouping: :auto),
            )
            assert_equal(
              [
                { type: :minus_sign, value: "-" },
                { type: :number, value: "1.234,50" },
                { type: :literal, value: "\u00A0" },
                { type: :currency, value: "€" },
              ],
              eur.format_to_parts(-1234.5, locale: :de),
            )
          end

          assert_equal "1HOST234,50", Worldwide::Numbers.new(locale: :pl).format(1234.5, decimal_places: 2, grouping: :auto)
          assert_equal "0HOST-DECIMAL13\u00A0€", eur.format_short(BigDecimal("0.125"), locale: :de, rounding_mode: :half_up)
          assert_equal "1HOST234,50", pln.format_to_parts(-1234.5, locale: :pl, grouping: :auto)[1][:value]
        end
      end

      test "lookups inside the block ignore a backend that the host installs on I18n::Config" do
        thread_backend = HostBackend.new
        thread_backend.store_translations(:de, numbers: { latn: { symbols: { decimal: "THREAD" } } })
        I18n::Config.any_instance.stubs(:backend).returns(thread_backend)

        assert_equal "THREAD", Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
        assert_equal ",", Worldwide::Cldr.with_bundled_data { Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de) }
      end

      test "lookups inside the block split keys on a dot, whatever the host's default separator" do
        original_separator = I18n.default_separator
        I18n.default_separator = "|"

        assert_equal("numbers latn symbols decimal", Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de))
        assert_equal(",", Worldwide::Cldr.with_bundled_data { Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de) })
      ensure
        I18n.default_separator = original_separator
      end

      test "a key missing in a locale falls back to bundled English data inside the block" do
        with_host_overrides do
          assert_equal "HOST today", Worldwide::Cldr.t("date_time_translation.today_at_time", locale: :af)
          assert_equal(
            "Today at %{time}",
            Worldwide::Cldr.with_bundled_data { Worldwide::Cldr.t("date_time_translation.today_at_time", locale: :af) },
          )
        end
      end

      test "a key missing in a locale falls back to English inside the block, whatever the host's default locale" do
        original_default_locale = I18n.default_locale
        I18n.default_locale = :fr

        assert_equal(
          Worldwide::Cldr.t("date_time_translation.today_at_time", locale: :fr),
          Worldwide::Cldr.t("date_time_translation.today_at_time", locale: :af),
        )
        assert_equal(
          "Today at %{time}",
          Worldwide::Cldr.with_bundled_data { Worldwide::Cldr.t("date_time_translation.today_at_time", locale: :af) },
        )
      ensure
        I18n.default_locale = original_default_locale
      end

      test "links between keys in the data resolve through bundled data inside the block" do
        # root links lists.or_narrow to lists.or_short, and lists.or_short to lists.or.
        with_host_overrides do
          assert_equal "HOST {0} {1}", Worldwide::Cldr.t("lists.or_narrow.2", locale: :de)
          assert_equal "{0} oder {1}", Worldwide::Cldr.with_bundled_data { Worldwide::Cldr.t("lists.or_narrow.2", locale: :de) }
        end
      end

      test "lookups inside the block can use a locale that the host does not make available" do
        original_locales = I18n.available_locales
        I18n.available_locales = [:en, :de]

        assert_raises(I18n::InvalidLocale) { Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :ja) }
        assert_equal(".", Worldwide::Cldr.with_bundled_data { Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :ja) })
      ensure
        I18n.available_locales = original_locales
      end

      test "lookups inside the block work when the host's current locale is one that bundled data lacks" do
        eur = Worldwide.currency(code: "EUR")
        decimal = ->(**options) { Worldwide::Cldr.t("numbers.latn.symbols.decimal", **options) }

        [true, false].each do |enforce|
          with_host_i18n(available_locales: I18n.available_locales + [:"en-XX"], enforce_available_locales: enforce) do
            I18n.with_locale(:"en-XX") do
              assert_equal "1.234,50\u00A0€", eur.format_short(1234.5, locale: :de)
              assert_equal ".", decimal.call

              Worldwide::Cldr.with_bundled_data do
                assert_equal "1.234,50\u00A0€", eur.format_short(1234.5, locale: :de)
                assert_equal ",", decimal.call(locale: :de)
                assert_equal :"en-XX", I18n.locale

                # A lookup that uses the current locale still checks it.
                if enforce
                  assert_raises(I18n::InvalidLocale) { decimal.call }
                else
                  assert_equal ".", decimal.call
                end
              end

              assert_equal :"en-XX", I18n.locale
            end
          end
        end
      end

      test "a lookup loads only the data for the locales and first key segments it needs" do
        with_fresh_bundled_data do |source|
          Worldwide::Cldr.with_bundled_data { Worldwide.currency(code: "EUR").format_short(1234.5, locale: :"de-AT") }

          assert_equal(
            { "de-AT": [:currencies, :numbers], de: [:currencies, :numbers] },
            source.backend.loaded_segments,
          )
          assert_equal false, source.backend.whole_locale_loaded?(:de)
        end
      end

      test "a lookup whose first key segment no file family lists loads the whole locale" do
        with_fresh_bundled_data do |source|
          with_yaml_files("ja.yml" => { "ja" => { "unlisted_segment" => { "value" => "from file" } } }) do |paths|
            Worldwide::Config.add_bundled_data_paths(paths)

            Worldwide::Cldr.with_bundled_data do
              assert_equal "from file", Worldwide::Cldr.t("unlisted_segment.value", locale: :ja)
              assert_equal ".", Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :ja)
            end

            assert_equal true, source.backend.whole_locale_loaded?(:ja)
            assert_includes source.backend.loaded_segments[:ja], :numbers
          end
        end
      end

      test "a family of files missing from the family map is still read" do
        families = BundledData::SEGMENTS_BY_FAMILY.except("cldr/lists", "other/lists")

        with_fresh_bundled_data(segments_by_family: families) do |source|
          Worldwide::Cldr.with_bundled_data do
            assert_equal "a, b oder c", Worldwide.lists.format(["a", "b", "c"], join: :or, locale: :de)
            assert_equal ",", Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
          end

          assert_equal true, source.backend.whole_locale_loaded?(:de)
        end
      end

      test "every bundled file holds only the keys that the family map lists for it" do
        source = BundledData.new
        index = source.send(:build_index)
        loader = I18n::Backend::Simple.new
        mismatches = []
        families = Set.new

        index.each_entry do |locale, family, path|
          families << family
          listed = BundledData::SEGMENTS_BY_FAMILY[family]
          next mismatches << [path, family, :unlisted_family] if listed.nil?

          segments = if path.end_with?(".rb")
            data, = loader.send(:load_rb, path)
            data.transform_values { |tree| tree.keys.map(&:to_s) }
          else
            collector = SegmentCollector.new
            Psych::Parser.new(collector).parse(File.read(path), path)
            collector.segments
          end

          unexpected = segments.fetch(locale.to_s, segments.fetch(locale, [])).map(&:to_sym) - listed
          mismatches << [path, family, unexpected] unless unexpected.empty?
        end

        assert_empty mismatches
        assert_equal BundledData::SEGMENTS_BY_FAMILY.keys.sort, families.to_a.sort
        assert_equal Worldwide::Config::REQUIRED_CLDR_DATA.map { |component| "cldr/#{component}" }.sort, families.grep(%r{\Acldr/}).sort
      end

      test "a file that holds another locale's data does not change that locale" do
        # data/other/hand_translated/mi.yml holds data under en:, and data/cldr/locales/sr-Cyrl/plurals.rb under sr_Cyrl:.
        with_fresh_bundled_data do |source|
          Worldwide::Cldr.with_bundled_data do
            assert_equal false, Worldwide::Cldr.exists?("date_time_translation.today_at_time", locale: :mi)
            Worldwide::Cldr.exists?("i18n.plural.rule", locale: :"sr-Cyrl")
          end

          assert_includes source.backend.loaded_segments[:mi], :date_time_translation
          refute_includes source.backend.translations.keys, :en
          refute_includes source.backend.translations.keys, :sr_Cyrl
        end
      end

      test "bundled lookups match lookups through a host configured with configure_i18n" do
        locales = [:en, :"en-IE", :"en-IN", :de, :"de-CH", :fr, :"fr-CA", :ja, :ar, :he, :pl, :es, :"pt-PT", :"zh-Hant-HK", :sr, :"sr-Cyrl", :ru]
        codes = ["USD", "EUR", "JPY", "KWD", "HKD", "CHF", "INR", "PLN", "XXX"]
        amounts = [0, -1234.5, 1234567.891, BigDecimal("1234.565")]
        calls = []

        locales.each do |locale|
          codes.each do |code|
            currency = Worldwide.currency(code: code)
            calls << -> { currency.symbol(locale: locale) }
            calls << -> { I18n.with_locale(locale) { currency.label(count: 2) } }
            amounts.each do |amount|
              calls << -> { currency.format_short(amount, locale: locale) }
              calls << -> { currency.format_explicit(amount, locale: locale, humanize: :short) }
              calls << -> { currency.format_to_parts(amount, locale: locale, grouping: :auto, rounding_mode: :half_up) }
            end
          end
          numbers = Worldwide::Numbers.new(locale: locale)
          calls << -> { numbers.format(0.4567, percent: true, decimal_places: 1) }
          calls << -> { numbers.format(1234567, humanize: :long) }
          calls << -> { Worldwide.lists.format(["a", "b", "c"], locale: locale) }
          calls << -> { I18n.with_locale(locale) { Worldwide.units.format(5, :kilogram, humanize: :long) } }
          calls << -> { Worldwide.region(code: "CA").zone(code: "QC").full_name(locale: locale) }
          calls << -> { Worldwide::Locale.new("pt-BR").name(locale: locale) }
          calls << -> { Worldwide::Cldr.t("date.formats.long", locale: locale) }
        end

        legacy = calls.map(&:call)
        bundled = Worldwide::Cldr.with_bundled_data { calls.map(&:call) }

        assert_equal legacy, bundled
      end

      test "threads and fibers in either mode never read the other mode's data" do
        errors = Queue.new

        with_host_overrides do
          threads = Array.new(8) do |thread_index|
            Thread.new do
              100.times do |iteration|
                if (thread_index + iteration).even?
                  Worldwide::Cldr.with_bundled_data do
                    value = Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
                    errors << [:bundled, value] unless value == ","
                    Fiber.new do
                      inner = Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
                      expected = Fiber.respond_to?(:[]) ? "," : "HOST-DECIMAL"
                      errors << [:fiber_in_block, inner] unless inner == expected
                    end.resume
                  end
                else
                  value = Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
                  errors << [:legacy, value] unless value == "HOST-DECIMAL"
                  Fiber.new do
                    Worldwide::Cldr.with_bundled_data do
                      inner = Worldwide.currency(code: "EUR").format_short(1234.5, locale: :de)
                      errors << [:bundled_fiber, inner] unless inner == "1.234,50\u00A0€"
                    end
                  end.resume
                  after = Worldwide.currency(code: "EUR").format_short(1234.5, locale: :de)
                  errors << [:legacy_after_fiber, after] unless after == "1.234HOST-DECIMAL50\u00A0€"
                end
              end
            end
          end
          threads.each(&:join)
        end

        leaked = []
        leaked << errors.pop until errors.empty?

        assert_empty leaked.uniq
      end

      test "a thread inside the block and a thread outside it read their own data while both are running" do
        entered = Queue.new
        checked = Queue.new
        results = {}

        with_host_overrides do
          bundled_thread = Thread.new do
            Worldwide::Cldr.with_bundled_data do
              entered << true
              checked.pop
              results[:bundled] = Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
            end
          end

          entered.pop
          results[:legacy] = Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
          checked << true
          bundled_thread.join
        end

        assert_equal({ legacy: "HOST-DECIMAL", bundled: "," }, results)
      end

      test "a fiber inside the block does not change the data its thread reads between resumes" do
        with_host_overrides do
          fiber = Fiber.new do
            Worldwide::Cldr.with_bundled_data do
              Fiber.yield(Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de))
              Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
            end
          end

          assert_equal ",", fiber.resume
          assert_equal "HOST-DECIMAL", Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
          assert_equal false, Worldwide::Cldr.bundled_data?
          assert_equal ",", fiber.resume
        end
      end

      test "a thread started inside the block reads legacy data after the block returns" do
        started = Queue.new
        block_returned = Queue.new
        results = {}

        with_host_overrides do
          thread = nil
          Worldwide::Cldr.with_bundled_data do
            thread = Thread.new do
              results[:inside] = Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
              started << true
              block_returned.pop
              results[:after] = Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
              results[:after_bundled_data] = Worldwide::Cldr.bundled_data?
            end
            started.pop
          end
          block_returned << true
          thread.join
        end

        # Ruby 3.2 and later copy fiber storage into a new thread, so the thread starts in bundled mode.
        # Without fiber storage, the scope is fiber-local, so the thread starts in legacy mode.
        assert_equal Fiber.respond_to?(:[]) ? "," : "HOST-DECIMAL", results[:inside]
        assert_equal "HOST-DECIMAL", results[:after]
        assert_equal false, results[:after_bundled_data]
      end

      test "a fiber created inside the block reads legacy data when resumed after the block returns" do
        with_host_overrides do
          fiber = nil
          Worldwide::Cldr.with_bundled_data do
            fiber = Fiber.new do
              loop { Fiber.yield(Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)) }
            end

            assert_equal Fiber.respond_to?(:[]) ? "," : "HOST-DECIMAL", fiber.resume
          end

          assert_equal "HOST-DECIMAL", fiber.resume
        end
      end

      test "a thread started inside a nested block reads bundled data until the outermost block returns" do
        step = Queue.new
        results = Queue.new
        read = -> { results << [Worldwide::Cldr.bundled_data?, Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)] }

        with_host_overrides do
          thread = nil
          Worldwide::Cldr.with_bundled_data do
            Worldwide::Cldr.with_bundled_data do
              thread = Thread.new do
                read.call
                2.times do
                  step.pop
                  read.call
                end
              end

              assert_equal [true, ","], results.pop
            end

            step << :inner_block_returned

            assert_equal [true, ","], results.pop
          end

          step << :outer_block_returned

          assert_equal [false, "HOST-DECIMAL"], results.pop
          thread.join
        end
      end

      test "a thread that opens its own block keeps reading bundled data in it after the block it started in returns" do
        opened = Queue.new
        parent_returned = Queue.new
        read = -> { [Worldwide::Cldr.bundled_data?, Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)] }

        with_host_overrides do
          thread = nil
          Worldwide::Cldr.with_bundled_data do
            thread = Thread.new do
              inside = Worldwide::Cldr.with_bundled_data do
                opened << true
                parent_returned.pop
                read.call
              end
              [inside, read.call]
            end
            opened.pop
          end
          parent_returned << true

          assert_equal [[true, ","], [false, "HOST-DECIMAL"]], thread.value
        end
      end

      test "every way out of a block, nested or not, restores the enclosing state" do
        exits = {
          raise: -> { assert_raises(RuntimeError) { Worldwide::Cldr.with_bundled_data { raise "boom" } } },
          break: -> { [1].each { Worldwide::Cldr.with_bundled_data { break } } },
          next: -> { [1].each { Worldwide::Cldr.with_bundled_data { next } } },
          throw: -> { catch(:done) { Worldwide::Cldr.with_bundled_data { throw(:done) } } },
          return: -> { Worldwide::Cldr.with_bundled_data { return } },
          kill: -> { Thread.new { Worldwide::Cldr.with_bundled_data { Thread.current.kill } }.join },
        }

        exits.each do |name, exit_block|
          exit_block.call

          assert_equal false, Worldwide::Cldr.bundled_data?, name

          Worldwide::Cldr.with_bundled_data do
            exit_block.call

            assert_equal true, Worldwide::Cldr.bundled_data?, name
            assert_equal ",", Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de), name
          end

          assert_equal false, Worldwide::Cldr.bundled_data?, name
        end
      end

      test "the scope is kept in fiber storage when Ruby has it, and in fiber-local variables otherwise" do
        expected = Fiber.respond_to?(:[]) ? BundledDataScope::FiberStorage : BundledDataScope::FiberLocalStorage

        assert_equal expected, BundledDataScope::STORAGE
      end

      test "with fiber-local storage, threads and fibers created inside the block read legacy data" do
        Worldwide::Cldr.stubs(:bundled_data_storage).returns(BundledDataScope::FiberLocalStorage)
        decimal = -> { Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de) }

        with_host_overrides do
          results = Worldwide::Cldr.with_bundled_data do
            nested = Worldwide::Cldr.with_bundled_data { decimal.call }
            [Worldwide::Cldr.bundled_data?, decimal.call, nested, Thread.new { decimal.call }.value, Fiber.new { decimal.call }.resume]
          end

          assert_equal [true, ",", ",", "HOST-DECIMAL", "HOST-DECIMAL"], results
          assert_equal false, Worldwide::Cldr.bundled_data?
          assert_equal "HOST-DECIMAL", decimal.call
          assert_nil Thread.current[:worldwide_bundled_data_scope]
        end
      end

      test "a process that never enters the block builds and reads no bundled data" do
        script = <<~RUBY
          require "worldwide"
          require "tmpdir"

          I18n.available_locales = [:en, :de]
          Worldwide::Config.configure_i18n
          overlay = File.join(Dir.mktmpdir, "de.yml")
          File.write(overlay, "de:\\n  currencies:\\n    JEP:\\n      symbol: X\\n")
          Worldwide::Config.add_bundled_data_paths([overlay])
          Worldwide.currency(code: "EUR").format_short(1234.5, locale: :de)
          Worldwide::Numbers.new(locale: :de).format(1234.5, decimal_places: 2)
          Worldwide::Locale.new("fr").name(locale: :de)
          Worldwide::Cldr.bundled_data?
          print [
            Worldwide::Cldr::BundledData.instance.built?,
            ObjectSpace.each_object(Worldwide::Cldr::BundledBackend).count,
            ObjectSpace.each_object(Worldwide::Cldr::BundledConfig).count,
          ].inspect
        RUBY

        # Only stdout carries the result, so that a warning on stderr, such as one from the gemspec, can't fail the test.
        output, errors, status = Open3.capture3(RbConfig.ruby, "-I", File.expand_path("../../../lib", __dir__), "-e", script)

        assert_predicate status, :success?, "stdout: #{output}\nstderr: #{errors}"
        assert_equal "[false, 0, 0]", output, "stderr: #{errors}"
      end

      test "files registered with add_bundled_data_paths apply after Worldwide's data, inside the block only" do
        # One file per locale, named after it, with the locale as the only top-level key.
        files = {
          "ar.yml" => {
            "ar" => {
              "currencies" => {
                "JEP" => { "name" => "جنيه جيرزي", "symbol" => "£", "one" => "جنيه جيرزي", "other" => "جنيه جيرزي" },
              },
              "subdivisions" => { "usaa" => "القوات المسلحة الأمريكية" },
            },
          },
          "en.yml" => {
            "en" => {
              "currencies" => {
                "JEP" => { "name" => "Jersey Pound", "one" => "Jersey pound", "other" => "Jersey pounds", "symbol" => "£" },
              },
              "subdivisions" => { "gbbfp" => "British Forces" },
              "territories" => { "XK" => "Kosovo (registered)" },
              "units" => { "unit_length" => { "long" => { "volume_pint_imperial" => { "one" => "%{count} Imp. pint" } } } },
            },
          },
          "ja.yml" => { "ja" => { "currencies" => { "JEP" => { "symbol" => "ポンド" }, "EUR" => { "symbol" => "OVERLAY-€" } } } },
          "pt-BR.yml" => { "pt-BR" => { "currencies" => { "JEP" => { "name" => "Libra de Jersey", "symbol" => "£" } } } },
          "zh-CN.yml" => { "zh-CN" => { "currencies" => { "JEP" => { "symbol" => "zh-£" } } } },
        }
        jep = Worldwide.currency(code: "JEP")
        eur = Worldwide.currency(code: "EUR")

        with_fresh_bundled_data do
          with_yaml_files(files) do |_paths, directory|
            load_path = I18n.load_path.dup
            Worldwide::Config.add_bundled_data_paths(Dir[File.join(directory, "*.yml")])

            assert_equal load_path, I18n.load_path

            with_host_overrides(ar: { currencies: { JEP: { symbol: "HOST-£" } } }) do
              Worldwide::Cldr.with_bundled_data do
                assert_equal "£", jep.symbol(locale: :ar)
                assert_equal "£", jep.symbol(locale: :"ar-EG")
                assert_equal "جنيه جيرزي", Worldwide::Cldr.t("currencies.JEP.name", locale: :ar)
                assert_equal "القوات المسلحة الأمريكية", Worldwide::Cldr.t("subdivisions.usaa", locale: :ar)
                assert_equal "€", eur.symbol(locale: :ar)
                assert_equal "OVERLAY-€", Worldwide::Cldr.t("currencies.EUR.symbol", locale: :ja)
                assert_equal "ユーロ", Worldwide::Cldr.t("currencies.EUR.name", locale: :ja)
                assert_equal "£", jep.symbol(locale: :"pt-BR")
                assert_equal "Libra de Jersey", I18n.with_locale(:"pt-BR") { jep.name }
                assert_equal "zh-£", jep.symbol(locale: :"zh-CN")
                assert_equal "£", jep.symbol(locale: :en)
                assert_equal "Jersey Pound", I18n.with_locale(:en) { jep.name }
                assert_equal "Jersey pound", I18n.with_locale(:en) { jep.label(count: 1) }
                assert_equal "Jersey pounds", I18n.with_locale(:en) { jep.label(count: 2) }
                assert_equal "British Forces", Worldwide::Cldr.t("subdivisions.gbbfp", locale: :en)
                assert_equal "Kosovo (registered)", Worldwide::Cldr.t("territories.XK", locale: :en)
                assert_equal "Kosovo", Worldwide::Cldr.t("territories.XK", locale: :de)
                assert_equal "%{count} Imp. pint", Worldwide::Cldr.t("units.unit_length.long.volume_pint_imperial.one", locale: :en)
                assert_equal "%{count} kilograms", Worldwide::Cldr.t("units.unit_length.long.mass_kilogram.other", locale: :en)
              end

              assert_equal "HOST-£", jep.symbol(locale: :ar)
            end
          end
        end
      end

      test "files registered after a lookup apply to later lookups" do
        jep = Worldwide.currency(code: "JEP")

        with_fresh_bundled_data do |source|
          with_yaml_files(
            "ar.yml" => { "ar" => { "currencies" => { "JEP" => { "symbol" => "£" } } } },
            "later/ar.yml" => { "ar" => { "currencies" => { "JEP" => { "symbol" => "later" } } } },
          ) do |paths|
            Worldwide::Cldr.with_bundled_data do
              assert_nil jep.symbol(locale: :ar)

              Worldwide::Config.add_bundled_data_paths([paths[0]])

              assert_equal "£", jep.symbol(locale: :ar)
              assert_equal ",", Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)

              Worldwide::Config.add_bundled_data_paths([paths[1]])

              assert_equal "later", jep.symbol(locale: :ar)
            end

            loaded = source.backend.loaded_segments
            Worldwide::Config.add_bundled_data_paths(paths)

            assert_equal paths, source.paths
            assert_equal loaded, source.backend.loaded_segments, "registering the same files again keeps the data read"
          end
        end
      end

      test "a file registered later wins over one registered earlier" do
        with_fresh_bundled_data do
          with_yaml_files(
            "first/ar.yml" => { "ar" => { "currencies" => { "JEP" => { "symbol" => "first", "name" => "first name" } } } },
            "second/ar.yml" => { "ar" => { "currencies" => { "JEP" => { "symbol" => "second" } } } },
          ) do |paths|
            Worldwide::Config.add_bundled_data_paths([paths[0]])
            Worldwide::Config.add_bundled_data_paths([paths[1]])

            Worldwide::Cldr.with_bundled_data do
              assert_equal "second", Worldwide::Cldr.t("currencies.JEP.symbol", locale: :ar)
              assert_equal "first name", Worldwide::Cldr.t("currencies.JEP.name", locale: :ar)
            end
          end
        end
      end

      test "a registered file changes only the locale it is named after" do
        with_fresh_bundled_data do
          with_yaml_files(
            "ja.yml" => {
              "ja" => { "currencies" => { "JEP" => { "symbol" => "ポンド" } } },
              "en" => { "currencies" => { "JEP" => { "symbol" => "NOT-EN" } } },
            },
          ) do |paths|
            Worldwide::Config.add_bundled_data_paths(paths)

            Worldwide::Cldr.with_bundled_data do
              assert_equal "ポンド", Worldwide::Cldr.t("currencies.JEP.symbol", locale: :ja)
              assert_equal "£", Worldwide::Cldr.t("currencies.JEP.symbol", locale: :en)
            end
          end
        end
      end

      test "a path registered again keeps its place" do
        with_fresh_bundled_data do |source|
          with_yaml_files(
            "first/ar.yml" => { "ar" => { "currencies" => { "JEP" => { "symbol" => "first" } } } },
            "second/ar.yml" => { "ar" => { "currencies" => { "JEP" => { "symbol" => "second" } } } },
          ) do |paths|
            Worldwide::Config.add_bundled_data_paths([paths[0]])
            Worldwide::Config.add_bundled_data_paths([paths[1]])
            Worldwide::Config.add_bundled_data_paths([paths[0]])

            assert_equal paths, source.paths
            assert_equal "second", Worldwide::Cldr.with_bundled_data { Worldwide::Cldr.t("currencies.JEP.symbol", locale: :ar) }
          end
        end
      end

      test "registered files may use anchors, aliases and Symbol values" do
        yaml = <<~YAML
          ja:
            currencies:
              JEP: &jersey
                symbol: :currencies.GBP.symbol
                name: &name Jersey Pound
              KID:
                <<: *jersey
                name: Kiribati Dollar
              GGP:
                name: *name
        YAML

        with_fresh_bundled_data do
          with_yaml_files("ja.yml" => yaml) do |paths|
            Worldwide::Config.add_bundled_data_paths(paths)

            Worldwide::Cldr.with_bundled_data do
              assert_equal "£", Worldwide::Cldr.t("currencies.JEP.symbol", locale: :ja)
              assert_equal "£", Worldwide::Cldr.t("currencies.KID.symbol", locale: :ja)
              assert_equal "Kiribati Dollar", Worldwide::Cldr.t("currencies.KID.name", locale: :ja)
              assert_equal "Jersey Pound", Worldwide::Cldr.t("currencies.GGP.name", locale: :ja)
            end
          end
        end
      end

      test "a registered file that is not plain YAML data fails to load with an error that names it" do
        files = {
          "ja.yml" => "ja:\n  currencies:\n    JEP: !ruby/object:Object {}\n",
          "th.yml" => "th:\n  currencies: [\n",
        }

        with_fresh_bundled_data do |source|
          with_yaml_files(files) do |paths|
            Worldwide::Config.add_bundled_data_paths(paths)

            Worldwide::Cldr.with_bundled_data do
              paths.each do |path|
                locale = File.basename(path, ".yml").to_sym

                # A failed load keeps nothing, so the next lookup reads the file again and fails the same way.
                2.times do
                  error = assert_raises(I18n::InvalidLocaleData) { Worldwide::Cldr.t("currencies.EUR.symbol", locale: locale) }

                  assert_includes error.message, path
                end
              end

              error = assert_raises(I18n::InvalidLocaleData) { Worldwide::Cldr.t("currencies", locale: :ja) }

              assert_includes error.message, "Tried to load unspecified class: Object"
              assert_equal ",", Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
            end

            assert_equal [:de], source.backend.loaded_segments.keys
            assert_equal "€", Worldwide::Cldr.t("currencies.EUR.symbol", locale: :ja)
          end
        end
      end

      test "lookups inside the block interpolate values as I18n does by default, whatever the host's settings" do
        patterns = I18n.config.interpolation_patterns + [/\{(\w+)\}/]
        with_host_interpolation(patterns: patterns, missing_argument_handler: ->(key, _values, _string) { "<#{key}?>" }) do
          lookup = -> { Worldwide::Cldr.t("lists.default.2", locale: :en, other: 1) }

          assert_equal "<0?> and <1?>", lookup.call
          assert_equal "{0} and {1}", Worldwide::Cldr.with_bundled_data { lookup.call }
          assert_raises(I18n::MissingInterpolationArgument) do
            Worldwide::Cldr.with_bundled_data { Worldwide::Cldr.t("units.unit_length.long.duration_day.one", locale: :en, other: 1) }
          end
        end
      end

      test "bundled data cannot be changed through the backend" do
        with_fresh_bundled_data do |source|
          assert_raises(FrozenError) do
            source.backend.store_translations(:de, numbers: { latn: { symbols: { decimal: "X" } } })
          end
          Worldwide::Cldr.with_bundled_data do
            assert_equal ",", Worldwide::Cldr.t("numbers.latn.symbols.decimal", locale: :de)
          end
        end
      end

      test "data returned inside the block cannot be changed, so later lookups are unaffected" do
        with_fresh_bundled_data do
          Worldwide::Cldr.with_bundled_data do
            currencies = Worldwide::Cldr.t(:currencies, locale: :en)

            assert_raises(FrozenError) { currencies[:EUR] = { symbol: "X" } }
            assert_raises(FrozenError) { currencies[:EUR][:name] << "X" }
            # Read from a Ruby file.
            assert_raises(FrozenError) { Worldwide::Cldr.t("i18n.plural.keys", locale: :en) << :many }
            assert_raises(FrozenError) { Worldwide::Cldr.t(".", locale: :en)[:currencies] = {} }
            # A String is returned as a copy.
            Worldwide::Cldr.t("currencies.EUR.symbol", locale: :en) << "X"

            assert_equal "€", Worldwide::Cldr.t("currencies.EUR.symbol", locale: :en)
            assert_equal "Euro", Worldwide::Cldr.t("currencies.EUR.name", locale: :en)
            assert_equal "€", Worldwide.currency(code: "EUR").symbol(locale: :en)
            assert_equal [:one, :other], Worldwide::Cldr.t("i18n.plural.keys", locale: :en)
            assert_equal :one, Worldwide::Cldr.t("i18n.plural", locale: :en)[:rule].call(1)
            assert_equal "1 day", Worldwide::Cldr.t("units.unit_length.long.duration_day", locale: :en, count: 1)
          end
        end
      end

      test "everything that the bundled data holds is frozen, apart from plural rules" do
        with_fresh_bundled_data do |source|
          with_yaml_files(
            "de.yml" => { "de" => { "currencies" => { "EUR" => { "symbol" => "OVERLAY-€" } }, "unlisted_segment" => { "a" => ["b"] } } },
          ) do |paths|
            Worldwide::Config.add_bundled_data_paths(paths)

            Worldwide::Cldr.with_bundled_data do
              Worldwide.currency(code: "EUR").format_short(1234.5, locale: :"de-AT")
              Worldwide::Cldr.t("unlisted_segment.a", locale: :de)
              Worldwide::Cldr.t("i18n.plural", locale: :en)
            end

            unfrozen = []
            walk = lambda do |value, path|
              case value
              when Hash then value.each { |key, child| walk.call(child, [*path, key]) }
              when Array then value.each_with_index { |child, index| walk.call(child, [*path, index]) }
              end
              unfrozen << path if (value.is_a?(Hash) || value.is_a?(Array) || value.is_a?(String)) && !value.frozen?
            end
            translations = source.backend.translations
            translations.each { |locale, data| walk.call(data, [locale]) }

            assert_equal [:de, :"de-AT", :en], translations.keys.sort
            assert_equal true, source.backend.whole_locale_loaded?(:de)
            assert_empty unfrozen
          end
        end
      end
    end
  end
end

# frozen_string_literal: false

require "parser/current"
require "worldwide"
require "yaml"

require_relative "flatten_hash"
require_relative "unflatten_hash"
require_relative "sort_yaml"

require_relative "currency_patches"

module Worldwide
  module Cldr
    class Patch
      class NotNeededError < StandardError
        def initialize(message)
          super("#{message} Perhaps this patch is no longer needed?")
        end
      end

      class Patcher
        include CurrencyPatches

        # There are some known problems with the CLDR data.
        # While we wait for the Unicode Consortium to respond / fix these issues,
        # we work around them by patching the data here.
        def perform
          # Clean up previous patches
          FileUtils.rm_rf(Worldwide::Paths::CLDR_ROOT)

          # Copy all the files from the exported CLDR data
          FileUtils.cp_r("#{Worldwide::Cldr::Puller::EXPORTED_CLDR_DIR}/.", Worldwide::Paths::CLDR_ROOT)

          # Load the existing files
          cldr_locales = Dir[File.join(Worldwide::Paths::CLDR_ROOT, "locales", "*")].map { |path| File.basename(path) }
          I18n.available_locales = cldr_locales
          Worldwide::Config.configure_i18n

          # https://unicode-org.atlassian.net/browse/CLDR-13408
          patch_file(:en, "subdivisions.yml", [:subdivisions, :nzmbh], "Marl", "Marlborough")

          # https://unicode-org.atlassian.net/browse/CLDR-15825
          patch_file(:en, "subdivisions.yml", [:subdivisions, :nzmwt], "Manawatu-Wanganui", "Manawatū-Whanganui")

          # ZA-GT is the old ISO code for Gauteng.  ISO replaced it with ZA-GP in 2007.
          # CLDR and Google both seem to still be stuck on ZA-GT, so we need to default to that
          # and treat ZA-GP as an altenate code for the same zone.
          # CLDR has translated names for ZA-GT and ZA-GP, but only has the name in English for ZA-GP,
          # whereas it has names in many locales for ZA-GT.
          # If we leave 'zagp:' in the subdivisions.yml file, then we'll auto-construct two
          # Worldwide::Zone objects (for both 'zagp' and 'zagt') which will cause problems.
          # So, here, we remove the single (English) translation for zagp.
          patch_file_delete_keys(:en, "subdivisions.yml", [:subdivisions], [:zagp])

          # Gabriela Jungblut has confirmed that the correct pluralization in both pt-PT and pt-BR is:
          #   0 itens criados.
          #   1 item criado.
          #   2 itens criados.
          # CLDR has an appropriate rule defined for pt-PT, but its pt rule (which is inherited by pt-BR)
          # renders `0 item criado`, which is wrong.
          # So, here we apply the `pt-PT` rule to `pt` (and, transitively, `pt-BR`).
          copy_file(:"pt-PT", :pt, "plurals.rb")

          # Decimal marker and grouping character for some Spanish locales need explicit overrides
          # from the generic `es` locale, because the countries don't follow the convention used in Spain.
          # Sources:
          #   - https://en.wikipedia.org/wiki/Decimal_separator
          #   - https://www.localeplanet.com/icu/decimal-symbols.html
          patch_file("es-PH", "numbers.yml", [:numbers, :latn, :symbols, :decimal], nil, ".", allow_file_creation: true)
          patch_file("es-PH", "numbers.yml", [:numbers, :latn, :symbols, :group], nil, ",")

          # CLDR says just "mille", relying on the fact that `one` will only be used for count == 1.
          # But that's what the explicit `1` key is for.
          patch_file(:it, "numbers.yml", [:numbers, :latn, :formats, :decimal, :patterns, :long, :standard, :"1000", :one], "mille", "0 mille")

          # Large number formatting for es
          patch_file(:es, "numbers.yml", [:numbers, :latn, :formats, :decimal, :patterns, :short, :standard, :"10000000000", :one], "00 mil M", "00000 M")
          patch_file(:es, "numbers.yml", [:numbers, :latn, :formats, :decimal, :patterns, :short, :standard, :"10000000000", :other], "00 mil M", "00000 M")
          patch_file(:es, "numbers.yml", [:numbers, :latn, :formats, :currency, :patterns, :short, :standard, :"10000000000", :one], "00 mil M¤", "00000 M¤")
          patch_file(:es, "numbers.yml", [:numbers, :latn, :formats, :currency, :patterns, :short, :standard, :"10000000000", :other], "00 mil M¤", "00000 M¤")
          patch_file(:es, "numbers.yml", [:numbers, :latn, :formats, :decimal, :patterns, :short, :standard, :"100000000000", :one], "000 mil M", "000000 M")
          patch_file(:es, "numbers.yml", [:numbers, :latn, :formats, :decimal, :patterns, :short, :standard, :"100000000000", :other], "000 mil M", "000000 M")
          patch_file(:es, "numbers.yml", [:numbers, :latn, :formats, :currency, :patterns, :short, :standard, :"100000000000", :one], "000 mil M¤", "000000 M¤")
          patch_file(:es, "numbers.yml", [:numbers, :latn, :formats, :currency, :patterns, :short, :standard, :"100000000000", :other], "000 mil M¤", "000000 M¤")

          # Compact number formatting for es-MX is incorrect
          number_keys = ["1000", "10000", "100000", "1000000", "10000000", "100000000", "1000000000"]
          existing_values = ["0 k¤", "00 k¤", "000 k¤", "0 M¤", "00 M¤", "000 M¤", "0000 M¤"]
          new_values = ["¤0 K", "¤00 K", "¤000 K", "¤0 M", "¤00 M", "¤000 M", "¤0000 M"]
          number_keys.zip(existing_values, new_values) do |number_key, existing_value, new_value|
            patch_file(:"es-MX", "numbers.yml", [:numbers, :latn, :formats, :currency, :patterns, :short, :standard, number_key.to_sym, :one], existing_value, new_value)
            patch_file(:"es-MX", "numbers.yml", [:numbers, :latn, :formats, :currency, :patterns, :short, :standard, number_key.to_sym, :other], existing_value, new_value)
          end

          # Re: subdivisions of Argentina
          # country_db used to label:
          #   - `arb` as `Buenos Aires`
          #   - `arc` as `Ciudad Autónoma de Buenos Aires`
          # CLDR labels them:
          #   - `arb` as `Buenos Aires Province` (en) / `provincia de Buenos Aires` (es)
          #   - `arc` as `Buenos Aires` (en and es)
          # This is causing confusion as people mistakenly select the wrong subdivision (and get that shipping rate).
          # Here, we patch things to make it clear that `arc` is the city for de, en, fr, it, ja, pt, zh-CN and zh-TW.
          # We also override the es translations to remove `provincia de` as customers prefer the shorter forms.
          #
          # Reported upstream: https://unicode-org.atlassian.net/projects/CLDR/issues/CLDR-14091
          #
          patch_file(:de, "subdivisions.yml", [:subdivisions, :arc], "Buenos Aires", "Autonome Stadt Buenos Aires")
          patch_file(:en, "subdivisions.yml", [:subdivisions, :arc], "Buenos Aires", "Buenos Aires (Autonomous City)")
          patch_file(:fr, "subdivisions.yml", [:subdivisions, :arc], "Buenos Aires", "ville Autonome de Buenos Aires")
          patch_file(:it, "subdivisions.yml", [:subdivisions, :arc], "Buenos Aires", "Città Autonoma di Buenos Aires")
          patch_file(:ja, "subdivisions.yml", [:subdivisions, :arc], "ブエノスアイレス", "ブエノスアイレス自治都市")
          patch_file(:pt, "subdivisions.yml", [:subdivisions, :arc], "Buenos Aires²", "Cidade Autônoma de Buenos Aires")
          # Note that :zh is used for :'zh-CN'.  :'zh-TW' is copied from :'zh-Hant', which is set separately.
          patch_file(:zh, "subdivisions.yml", [:subdivisions, :arc], "布宜諾斯艾利斯", "布宜诺斯艾利斯自治市")
          patch_file("zh-Hant", "subdivisions.yml", [:subdivisions, :arc], nil, "布宜諾斯艾利斯自治市", allow_file_creation: true)
          patch_subdivisions(:es, [
            [:ara, "Provincia de Salta", "Salta"],
            [:arb, "provincia de Buenos Aires", "Buenos Aires (provincia)"],
            [:arc, "Buenos Aires", "Ciudad Autónoma de Buenos Aires"],
            [:ard, "Provincia de San Luis", "San Luis"],
            [:are, "Provincia de Entre Ríos", "Entre Ríos"],
            [:arf, "Provincia de La Rioja", "La Rioja"],
            [:arg, "Provincia de Santiago del Estero", "Santiago del Estero"],
            [:arh, "Provincia del Chaco", "Chaco"],
            [:arj, "Provincia de San Juan", "San Juan"],
            # :ark, "Catamarca", is already correct in CLDR
            [:arl, "Provincia de La Pampa", "La Pampa"],
            [:arm, "Provincia de Mendoza", "Mendoza"],
            [:arn, "Provincia de Misiones", "Misiones"],
            [:arp, "Provincia de Formosa", "Formosa"],
            [:arq, "Provincia de Neuquén", "Neuquén"],
            [:arr, "Provincia de Río Negro", "Río Negro"],
            [:ars, "Provincia de Santa Fe", "Santa Fe"],
            [:art, "Provincia de Tucumán", "Tucumán"],
            [:aru, "Provincia del Chubut", "Chubut"],
            [:arv, "Provincia de Tierra del Fuego, Antártida e islas del Atlántico Sur", "Tierra del Fuego"],
            [:arw, "Provincia de Corrientes", "Corrientes"],
            [:arx, "Provincia de Córdoba", "Córdoba"],
            [:ary, "Provincia de Jujuy", "Jujuy"],
            [:arz, "Provincia de Santa Cruz", "Santa Cruz"],
          ])

          # Regions of Chile in Spanish
          patch_subdivisions(:es, [
            [:clai, "Región Aysén del General Carlos Ibáñez del Campo", "Aysén"],
            [:clan, "Región de Antofagasta", "Antofagasta"],
            [:clap, "Región de Arica y Parinacota", "Arica y Parinacota"],
            [:clar, "Región de la Araucanía", "Araucanía"],
            [:clat, "Región de Atacama", "Atacama"],
            # CLDR has "Región del Bío Bío", but Worldwide and Wikipedia's Spanish page agree that it's "Biobío"
            [:clbi, "Región del Bío Bío", "Biobío"],
            [:clco, "Región de Coquimbo", "Coquimbo"],
            [:clli, "Región de O’Higgins", "O’Higgins"],
            [:clll, "Región de Los Lagos", "Los Lagos"],
            [:cllr, "Región de Los Ríos", "Los Ríos"],
            [:clma, "Región de Magallanes y de la Antártica Chilena", "Magallanes"],
            [:clml, "Región del Maule", "Maule"],
            [:clnb, "Región de Ñuble", "Ñuble"],
            [:clrm, "Región Metropolitana de Santiago", "Santiago"],
            [:clta, "Región de Tarapacá", "Tarapacá"],
            [:clvs, "Región de Valparaíso", "Valparaíso"],
          ])

          # Provinces of Italy in Italian
          # Reported upstream: https://unicode-org.atlassian.net/browse/CLDR-14092
          patch_subdivisions(:it, [
            [:itag, "provincia di Agrigento", "Agrigento"],
            [:ital, "provincia di Alessandria", "Alessandria"],
            [:itan, "provincia di Ancona", "Ancona"],
            [:itap, "provincia di Ascoli Piceno", "Ascoli Piceno"],
            [:itaq, "provincia dell’Aquila", "L'Aquila"],
            [:itar, "provincia di Arezzo", "Arezzo"],
            [:itat, "provincia di Asti", "Asti"],
            [:itav, "provincia di Avellino", "Avellino"],
            [:itba, "provincia di Bari", "Bari"],
            [:itbg, "provincia di Bergamo", "Bergamo"],
            [:itbi, "provincia di Biella", "Biella"],
            [:itbl, "provincia di Belluno", "Belluno"],
            [:itbn, "provincia di Benevento", "Benevento"],
            [:itbo, "provincia di Bologna", "Bologna"],
            [:itbr, "provincia di Brindisi", "Brindisi"],
            [:itbs, "provincia di Brescia", "Brescia"],
            [:itbt, "provincia di Barletta-Andria-Trani", "Barletta-Andria-Trani"],
            [:itbz, "provincia autonoma di Bolzano", "Bolzano"],
            [:itca, "provincia di Cagliari", "Cagliari"],
            [:itcb, "provincia di Campobasso", "Campobasso"],
            [:itce, "provincia di Caserta", "Caserta"],
            [:itch, "provincia di Chieti", "Chieti"],
            [:itci, "provincia di Carbonia-Iglesias", "Carbonia-Iglesias"],
            [:itcl, "provincia di Caltanissetta", "Caltanissetta"],
            [:itcn, "Provincia di Cuneo", "Cuneo"],
            [:itco, "provincia di Como", "Como"],
            [:itcr, "provincia di Cremona", "Cremona"],
            [:itcs, "provincia di Cosenza", "Cosenza"],
            [:itct, "provincia di Catania", "Catania"],
            [:itcz, "provincia di Catanzaro", "Catanzaro"],
            [:iten, "provincia di Enna", "Enna"],
            [:itfc, "provincia di Forlì-Cesena", "Forlì-Cesena"],
            [:itfe, "provincia di Ferrara", "Ferrara"],
            [:itfg, "provincia di Foggia", "Foggia"],
            [:itfi, "provincia di Firenze", "Firenze"],
            [:itfm, "provincia di Fermo", "Fermo"],
            [:itfr, "provincia di Frosinone", "Frosinone"],
            [:itge, "città metropolitana di Genova", "Genova"],
            [:itgo, "provincia di Gorizia", "Gorizia"],
            [:itgr, "provincia di Grosseto", "Grosseto"],
            [:itim, "provincia di Imperia", "Imperia"],
            [:itis, "provincia di Isernia", "Isernia"],
            [:itkr, "provincia di Crotone", "Crotone"],
            [:itlc, "provincia di Lecco", "Lecco"],
            [:itle, "provincia di Lecce", "Lecce"],
            [:itli, "provincia di Livorno", "Livorno"],
            [:itlo, "provincia di Lodi", "Lodi"],
            [:itlt, "provincia di Latina", "Latina"],
            [:itlu, "provincia di Lucca", "Lucca"],
            [:itmb, "provincia di Monza e della Brianza", "Monza e Brianza"],
            [:itmc, "provincia di Macerata", "Macerata"],
            [:itme, "provincia di Messina", "Messina"],
            [:itmi, "provincia di Milano", "Milano"],
            [:itmn, "provincia di Mantova", "Mantova"],
            [:itmo, "provincia di Modena", "Modena"],
            [:itms, "provincia di Massa e Carrara", "Massa-Carrara"],
            [:itmt, "provincia di Matera", "Matera"],
            [:itna, "città metropolitana di Napoli", "Napoli"],
            [:itno, "provincia di Novara", "Novara"],
            [:itnu, "provincia di Nuoro", "Nuoro"],
            [:itog, "provincia dell’Ogliastra", "Ogliastra"],
            [:itor, "provincia di Oristano", "Oristano"],
            [:itot, "provincia di Olbia-Tempio", "Olbia-Tempio"],
            [:itpa, "provincia di Palermo", "Palermo"],
            [:itpc, "provincia di Piacenza", "Piacenza"],
            [:itpd, "provincia di Padova", "Padova"],
            [:itpe, "provincia di Pescara", "Pescara"],
            [:itpg, "provincia di Perugia", "Perugia"],
            [:itpi, "provincia di Pisa", "Pisa"],
            [:itpn, "provincia di Pordenone", "Pordenone"],
            [:itpo, "provincia di Prato", "Prato"],
            [:itpr, "provincia di Parma", "Parma"],
            [:itpt, "provincia di Pistoia", "Pistoia"],
            [:itpu, "provincia di Pesaro e Urbino", "Pesaro e Urbino"],
            [:itpv, "provincia di Pavia", "Pavia"],
            [:itpz, "provincia di Potenza", "Potenza"],
            [:itra, "provincia di Ravenna", "Ravenna"],
            [:itrc, "provincia di Reggio Calabria", "Reggio Calabria"],
            [:itre, "provincia di Reggio nell’Emilia", "Reggio Emilia"],
            [:itrg, "provincia di Ragusa", "Ragusa"],
            [:itri, "provincia di Rieti", "Rieti"],
            [:itrm, "provincia di Roma", "Roma"],
            [:itrn, "provincia di Rimini", "Rimini"],
            [:itro, "provincia di Rovigo", "Rovigo"],
            [:itsa, "provincia di Salerno", "Salerno"],
            [:itsi, "provincia di Siena", "Siena"],
            [:itso, "provincia di Sondrio", "Sondrio"],
            [:itsp, "provincia della Spezia", "La Spezia"],
            [:itsr, "provincia di Siracusa", "Siracusa"],
            [:itss, "provincia di Sassari", "Sassari"],
            [:itsv, "provincia di Savona", "Savona"],
            [:itta, "provincia di Taranto", "Taranto"],
            [:itte, "provincia di Teramo", "Teramo"],
            [:ittn, "provincia autonoma di Trento", "Trento"],
            [:itto, "provincia di Torino", "Torino"],
            [:ittp, "provincia di Trapani", "Trapani"],
            [:ittr, "provincia di Terni", "Terni"],
            [:itts, "provincia di Trieste", "Trieste"],
            [:ittv, "provincia di Treviso", "Treviso"],
            [:itud, "provincia di Udine", "Udine"],
            [:itva, "provincia di Varese", "Varese"],
            [:itvb, "provincia del Verbano-Cusio-Ossola", "Verbano-Cusio-Ossola"],
            [:itvc, "provincia di Vercelli", "Vercelli"],
            [:itve, "provincia di Venezia", "Venezia"],
            [:itvi, "provincia di Vicenza", "Vicenza"],
            [:itvr, "provincia di Verona", "Verona"],
            [:itvs, "provincia del Medio Campidano", "Medio Campidano"],
            [:itvt, "provincia di Viterbo", "Viterbo"],
            [:itvv, "provincia di Vibo Valentia", "Vibo Valentia"],
          ])

          # Aosta Valley in Italy is both a region and a province
          # In 2019, ISO 3166 deleted IT-AO (the province) leaving only IT-23 (the region)
          #   https://www.iso.org/obp/ui/#iso:code:3166:IT
          # CLDR continues to have both, and Worldwide treats them as alternates for each other.
          # But, CLDR has slightly different names for the two in some lanugages, and that causes problems.
          # (In general, CLDR has "Aosta" for IT-AO, and "Aosta Valley" for IT-23.)
          # So, we'll override the names for IT-AO to set them equal to the name for IT-23 in our main locales.
          files_to_patch = Dir.glob(File.join([Worldwide::Paths::CLDR_ROOT, "locales", "*", "subdivisions.yml"]))
          raise "No CLDR files found to patch" if files_to_patch.empty?

          files_to_patch.each do |filepath|
            content = YAML.safe_load_file(filepath)
            locale = content.keys.first
            it23 = content[locale]["subdivisions"]["it23"]
            itao = content[locale]["subdivisions"]["itao"]
            unless it23 == itao
              if it23.nil?
                patch_file(locale, "subdivisions.yml", [:subdivisions, :it23], nil, itao)
              else
                patch_file(locale, "subdivisions.yml", [:subdivisions, :itao], itao, it23)
              end
            end
          end

          # Subdivisions of Japan in English
          #
          # A customer has requested that we remove macrons from English names of Japanese subdivisions,
          # for interoperation with Pitney-Bowes.
          # Aya Kamikawa has decided that we should do as the customer asks.
          patch_subdivisions(:en, [
            [:jp01, "Hokkaidō", "Hokkaido"],
            # Note that JP-13, Tokyo, is already missing the macrons in the data we get from CLDR.
            [:jp26, "Kyōto", "Kyoto"],
            [:jp27, "Ōsaka", "Osaka"],
            [:jp28, "Hyōgo", "Hyogo"],
            [:jp39, "Kōchi", "Kochi"],
            [:jp44, "Ōita", "Oita"],
          ])

          # Provinces of Panama in Spanish
          patch_subdivisions(:es, [
            [:pa1, "Provincia de Bocas del Toro", "Bocas del Toro"],
            [:pa2, "Provincia de Coclé", "Coclé"],
            [:pa3, "Provincia de Colón", "Colón"],
            [:pa4, "Provincia de Chiriquí", "Chiriquí"],
            [:pa5, "Provincia de Darién", "Darién"],
            [:pa6, "Provincia de Herrera", "Herrera"],
            [:pa7, "Provincia de Los Santos", "Los Santos"],
            [:pa8, "Provincia de Panamá", "Panamá"],
            [:pa9, "Provincia de Veraguas", "Veraguas"],
            [:pa10, "Provincia de Panamá Oeste", "Panamá Oeste"],
          ])

          # Departamentos of Peru in Spanish
          # Reported upstream: https://unicode-org.atlassian.net/browse/CLDR-14094
          patch_subdivisions(:es, [
            [:peama, "Departamento de Amazonas", "Amazonas"],
            [:peanc, "Departamento de Áncash", "Áncash"],
            [:peapu, "Departamento de Apurímac", "Apurímac"],
            [:peaya, "Departamento de Ayacucho", "Ayacucho"],
            [:pecaj, "Departamento de Cajamarca", "Cajamarca"],
            [:pecal, "Gobierno Regional del Callao", "Callao"],
            [:pecus, "Departamento de Cuzco", "Cuzco"],
            [:pehuc, "Departamento de Huánuco", "Huánuco"],
            [:pehuv, "Departamento de Huancavelica", "Huancavelica"],
            [:peica, "Departamento de Ica", "Ica"],
            [:pejun, "Departamento de Junín", "Junín"],
            [:pelal, "Departamento de La Libertad", "La Libertad"],
            [:pelam, "Departamento de Lambayeque", "Lambayeque"],
            [:pelim, "Lima", "Lima (Departamento)"],
            [:pelma, "Provincia de Lima", "Lima (Metropolitana)"],
            [:pelor, "Departamento de Loreto", "Loreto"],
            [:pemdd, "Departamento de Madre de Dios", "Madre de Dios"],
            [:pemoq, "Departamento de Moquegua", "Moquegua"],
            [:pepas, "Departamento de Pasco", "Pasco"],
            [:pepiu, "Departamento de Piura", "Piura"],
            [:pepun, "Departamento de Puno", "Puno"],
            [:pesam, "Departamento de San Martín", "San Martín"],
            [:petac, "Departamento de Tacna", "Tacna"],
            [:petum, "Departamento de Tumbes", "Tumbes"],
            [:peuca, "Departamento de Ucayali", "Ucayali"],
          ])

          # Lima department/province of Peru in English
          patch_subdivisions(:en, [
            [:pelim, "Lima Region", "Lima (Department)"],
            [:pelma, "Lima", "Lima (Metropolitan)"],
          ])

          # Districts of Portugal in Portuguese
          # Reported upstream: https://unicode-org.atlassian.net/browse/CLDR-14095
          patch_subdivisions(:pt, [
            # :pt01, "Aveiro" is already correct in CLDR
            [:pt02, "Distrito de Beja", "Beja"],
            [:pt03, "Distrito de Braga", "Braga"],
            # :pt04, "Bragança" is already correct in CLDR
            [:pt05, "Distrito de Castelo Branco", "Castelo Branco"],
            [:pt06, "Distrito de Coimbra", "Coimbra"],
            [:pt07, "Distrito de Évora", "Évora"],
            [:pt08, "Distrito de Faro", "Faro"],
            [:pt09, "Distrito da Guarda", "Guarda"],
            [:pt10, "Distrito de Leiria", "Leiria"],
            [:pt11, "Distrito de Lisboa", "Lisboa"],
            [:pt12, "Distrito de Portalegre", "Portalegre"],
            # :pt13, "Porto" is already correct in CLDR
            [:pt14, "Distrito de Santarém", "Santarém"],
            [:pt15, "Distrito de Setúbal", "Setúbal"],
            [:pt16, "Distrito de Viana do Castelo", "Viana do Castelo"],
            # :pt17, :pt18, and :pt20 are already correct in CLDR
            [:pt30, "Região Autónoma da Madeira", "Madeira"],
          ])

          # Provinces of Spain in Spanish
          # CLDR uses a mix of "provincia" and "Provincia", and sometimes leaves out "Provincia" altogether.
          # This makes it hard to find a province in the checkout list, and makes us look stupid.
          # Here we patch most of the names for subdivisions of Spain in the Spanish language.
          # We favour not including "Provincia de" because it's not needed to disambiguate.
          # Reported upstream:  https://unicode-org.atlassian.net/browse/CLDR-14034
          patch_subdivisions(:es, [
            [:esa, "Provincia de Alicante", "Alicante"],
            [:esab, "Provincia de Albacete", "Albacete"],
            [:esal, "Provincia de Almería", "Almería"],
            [:esav, "Provincia de Ávila", "Ávila"],
            [:esb, "Provincia de Barcelona", "Barcelona"],
            [:esba, "Provincia de Badajoz", "Badajoz"],
            [:esbu, "Provincia de Burgos", "Burgos"],
            [:esc, "Provincia de La Coruña", "La Coruña"],
            [:esca, "Provincia de Cádiz", "Cádiz"],
            [:escc, "Provincia de Cáceres", "Cáceres"],
            [:esco, "Provincia de Córdoba", "Córdoba"],
            [:escr, "Provincia de Ciudad Real", "Ciudad Real"],
            [:escs, "Provincia de Castellón", "Castellón"],
            [:escu, "Provincia de Cuenca", "Cuenca"],
            [:esgc, "Provincia de Las Palmas", "Las Palmas"],
            [:esgi, "Provincia de Gerona", "Gerona"],
            [:esgr, "Provincia de Granada", "Granada"],
            [:esgu, "Provincia de Guadalajara", "Guadalajara"],
            [:esh, "Provincia de Huelva", "Huelva"],
            [:eshu, "Provincia de Huesca", "Huesca"],
            [:esj, "Provincia de Jaén", "Jaén"],
            [:esl, "Provincia de Lérida", "Lérida"],
            [:esle, "Provincia de León", "León"],
            [:eslu, "Provincia de Lugo", "Lugo"],
            [:esm, "provincia de Madrid", "Madrid"],
            [:esma, "provincia de Málaga", "Málaga"],
            [:esmu, "provincia de Murcia", "Murcia"],
            [:esna, "Navarra²", "Navarra"],
            [:eso, "provincia de Asturias", "Asturias"],
            [:esor, "Provincia de Orense", "Orense"],
            [:esp, "Provincia de Palencia", "Palencia"],
            [:espm, "Islas Baleares²", "Islas Baleares"],
            [:espo, "Provincia de Pontevedra", "Pontevedra"],
            [:ess, "Cantabria²", "Cantabria"],
            [:essa, "Provincia de Salamanca", "Salamanca"],
            [:esse, "Provincia de Sevilla", "Sevilla"],
            [:essg, "Provincia de Segovia", "Segovia"],
            [:esso, "Provincia de Soria", "Soria"],
            [:est, "provincia de Tarragona", "Tarragona"],
            [:este, "Provincia de Teruel", "Teruel"],
            [:esto, "Provincia de Toledo", "Toledo"],
            [:estf, "Provincia de Santa Cruz de Tenerife", "Santa Cruz de Tenerife"],
            [:esv, "Provincia de Valencia", "Valencia"],
            [:esva, "Provincia de Valladolid", "Valladolid"],
            [:esz, "Provincia de Zaragoza", "Zaragoza"],
            [:esza, "Provincia de Zamora", "Zamora"],
          ])

          # Washington, DC has no Japanese translation in CLDR
          patch_subdivisions(:ja, [
            [:usdc, nil, "コロンビア特別区"],
          ])

          # A bug in the cldr-staging build means that these were incorrectly dropped.
          # Reported upstream: https://unicode-org.atlassian.net/browse/CLDR-15228
          patch_subdivisions(
            :br,
            [
              [:gbeng, nil, "Bro-Saoz"],
              [:gbsct, nil, "Skos"],
              [:gbwls, nil, "Kembre"],
            ],
            allow_file_creation: true,
          )
          patch_subdivisions(
            :ckb,
            [
              [:gbeng, nil, "ئینگلاند"],
              [:gbsct, nil, "سکۆتلەندا"],
              [:gbwls, nil, "وەیڵز"],
            ],
            allow_file_creation: true,
          )
          patch_subdivisions(
            :fil,
            [
              [:gbeng, nil, "England"],
              [:gbsct, nil, "Scotland"],
              [:gbwls, nil, "Wales"],
            ],
            allow_file_creation: true,
          )
          patch_subdivisions(
            :gd,
            [
              [:gbeng, nil, "Sasainn"],
              [:gbsct, nil, "Alba"],
              [:gbwls, nil, "A’ Chuimrigh"],
            ],
            allow_file_creation: true,
          )
          patch_subdivisions(
            :mt,
            [
              [:gbeng, nil, "l-Ingilterra"],
              [:gbsct, nil, "l-Iskozja"],
              [:gbwls, nil, "Wales"],
            ],
            allow_file_creation: true,
          )
          patch_subdivisions(:"zh-Hant", [
            [:gbeng, nil, "英格蘭"],
            [:gbsct, nil, "蘇格蘭"],
            [:gbwls, nil, "威爾斯"],
          ]) # This file already exists

          # Departments of El Salvador
          # CLDR's names for the departments of El Salvador are inconsistent, sometimes including "Department of" and sometimes not.
          # Similar inconsistencies exist in several languages.
          # For internal consistency in the departments list and consistency with what we've done for other countries, we favour not including
          # "Departament of" because it's not needed to disambiguate these regions.
          # Reported upstream: https://unicode-org.atlassian.net/browse/CLDR-17445
          patch_subdivisions(:ar, [
            [:svah, "إدارة أهواشابان", "أهواشابان"],
            [:svca, "إدارة كاباناس", "كاباناس"],
            [:svcu, "إدارة كوسكاتلان", "كوسكاتلان"],
            [:svli, "إدارة لا ليبرتاد", "لا ليبرتاد"],
            [:svmo, "إدارة مورازان", "مورازان"],
            [:svpa, "إدارة لاباز", "لاباز"],
            [:svsa, "إدارة سانتا آنا", "سانتا آنا"],
            [:svsm, "إدارة سان ميغيل", "سان ميغيل"],
            [:svso, "إدارة سونسونات", "سونسونات"],
            [:svss, "إدارة سان سلفادور", "سان سلفادور"],
            [:svsv, "إدارة سان فيسينتي", "سان فيسينتي"],
            [:svus, "إدارة أوسولوتان", "أوسولوتان"],
          ])
          patch_subdivisions(:bn, [
            [:svah, "আহোয়াচাপান বিভাগ", "আহোয়াচাপান"],
            [:svca, "কাবানাস বিভাগ", "কাবানাস"],
            [:svcu, "কুসকাতলান বিভাগ", "কুসকাতলান"],
            [:svli, "লা লিবারটেড বিভাগ", "লা লিবারটেড"],
            [:svmo, "মুরাজান বিভাগ", "মুরাজান"],
            [:svpa, "লা পাজ বিভাগ", "লা পাজ"],
            [:svsa, "স্যান্টা আনা বিভাগ", "স্যান্টা আনা"],
            [:svsm, "সান মিগুয়েল বিভাগ", "সান মিগুয়েল"],
            [:svso, "সোন্সোনাটে বিভাগ", "সোন্সোনাটে"],
            [:svss, "সান সাল্ভাদর বিভাগ", "সান সাল্ভাদর"],
            [:svsv, "সান ভিসেন্তে বিভাগ", "সান ভিসেন্তে"],
            [:svus, "উসুলুটান বিভাগ", "উসুলুটান"],
          ])
          patch_subdivisions(:ca, [
            [:svah, "Departament d’Ahuachapán", "Ahuachapán"],
            [:svca, "Departament de Cabañas", "Cabañas"],
            [:svch, "Departament de Chalatenango", "Chalatenango"],
            [:svcu, "Departament de Cuscatlán", "Cuscatlán"],
            [:svli, "Departament de La Libertad", "La Libertad"],
            [:svmo, "Departament de Morazán", "Morazán"],
            [:svpa, "Departament de La Paz", "La Paz"],
            [:svsa, "Departament de Santa Ana", "Santa Ana"],
            [:svsm, "Departament de San Miguel", "San Miguel"],
            [:svso, "Departament de Sonsonate", "Sonsonate"],
            [:svss, "Departament de San Salvador", "San Salvador"],
            [:svsv, "Departament de San Vicente", "San Vicente"],
            [:svun, "Departament de La Unión", "La Unión"],
            [:svus, "Departament d’Usulután", "Usulután"],
          ])
          patch_subdivisions(:ceb, [
            [:svah, "Departamento de Ahuachapán", "Ahuachapán"],
            [:svca, "Departamento de Cabañas", "Cabañas"],
            [:svch, "Departamento de Chalatenango", "Chalatenango"],
            [:svcu, "Departamento de Cuscatlán", "Cuscatlán"],
            [:svli, "Departamento de La Libertad", "La Libertad"],
            [:svmo, "Departamento de Morazán", "Morazán"],
            [:svpa, "Departamento de La Paz", "La Paz"],
            [:svsa, "Departamento de Santa Ana", "Santa Ana"],
            [:svsm, "Departamento de San Miguel", "San Miguel"],
            [:svso, "Departamento de Sonsonate", "Sonsonate"],
            [:svss, "Departamento de San Salvador", "San Salvador"],
            [:svsv, "Departamento de San Vicente", "San Vicente"],
            [:svus, "Departamento de Usulután", "Usulután"],
          ])
          patch_subdivisions(:cs, [
            [:svah, "Sonsonate", "Ahuachapán"], # ??? Czech is also missing translations for several other departments
            [:svso, "Sonsonate²", "Sonsonate"],
          ])
          patch_subdivisions(:da, [
            [:svah, "Ahuachapán Department", "Ahuachapán"],
            [:svca, "Cabañas Department", "Cabañas"],
            [:svcu, "Cuscatlán Department", "Cuscatlán"],
            [:svli, "La Libertad Department", "La Libertad"],
            [:svmo, "Morazán Department", "Morazán"],
            [:svpa, "La Paz Department", "La Paz"],
            [:svsa, "Santa Ana Department", "Santa Ana"],
            [:svsm, "San Miguel Department", "San Miguel"],
            [:svso, "Sonsonate Department", "Sonsonate"],
            [:svss, "San Salvador Department", "San Salvador"],
            [:svsv, "San Vicente Department", "San Vicente"],
            [:svus, "Usulután Department", "Usulután"],
          ])
          patch_subdivisions(:de, [
            [:svah, "Departamento Ahuachapán", "Ahuachapán"],
            [:svca, "Departamento Cabañas", "Cabañas"],
            [:svch, "Departamento Chalatenango", "Chalatenango"],
            [:svcu, "Departamento Cuscatlán", "Cuscatlán"],
            [:svli, "Departamento La Libertad", "La Libertad"],
            [:svmo, "Departamento Morazán", "Morazán"],
            [:svsa, "Departamento Santa Ana", "Santa Ana"],
            [:svsm, "Departamento San Miguel", "San Miguel"],
            [:svso, "Departamento Sonsonate", "Sonsonate"],
            [:svss, "Departamento San Salvador", "San Salvador"],
            [:svsv, "Departamento San Vicente", "San Vicente"],
            [:svun, "Departamento La Unión", "La Unión"],
          ])
          patch_subdivisions(:el, [
            [:svah, "Διαμέρισμα Αουατσαπάν", "Αουατσαπάν"],
            [:svca, "Διαμέρισμα Καμπάνιας", "Καμπάνιας"],
            [:svch, "Διαμέρισμα Τσαλατενάνγκο", "Τσαλατενάνγκο"],
            [:svcu, "Διαμέρισμα Κουσκατλάν", "Κουσκατλάν"],
            [:svli, "Διαμέρισμα Λα Λιμπερτάδ", "Λα Λιμπερτάδ"],
            [:svmo, "Διαμέρισμα Μοραζάν", "Μοραζάν"],
            [:svpa, "Διαμέρισμα Λα Παζ", "Λα Παζ"],
            [:svsa, "Διαμέρισμα Σάντα Άνα", "Σάντα Άνα"],
            [:svsm, "Διαμέρισμα Σαν Μιγκέλ", "Σαν Μιγκέλ"],
            [:svso, "Διαμέρισμα Σονσονάτε", "Σονσονάτε"],
            [:svss, "Διαμέρισμα Σαν Σαλβαδόρ", "Σαν Σαλβαδόρ"],
            [:svsv, "Διαμέρισμα Σαν Βισέντε", "Σαν Βισέντε"],
            [:svun, "Διαμέρισμα Λα Ουνιόν", "Λα Ουνιόν"],
            [:svus, "Διαμέρισμα Ουσουλουτάν", "Ουσουλουτάν"],
          ])
          patch_subdivisions(:es, [
            [:svah, "Departamento de Ahuachapán", "Ahuachapán"],
            [:svch, "Departamento de Chalatenango", "Chalatenango"],
            [:svli, "Departamento de La Libertad", "La Libertad"],
            [:svsa, "Departamento de Santa Ana", "Santa Ana"],
          ])
          patch_subdivisions(:eu, [
            [:svah, "Ahuachapán departamendua", "Ahuachapán"],
            [:svca, "Cabañas departamendua", "Cabañas"],
            [:svch, "Chalatenango departamendua", "Chalatenango"],
            [:svcu, "Cuscatlán departamendua", "Cuscatlán"],
            [:svli, "La Libertad departamendua", "La Libertad"],
            [:svmo, "Morazán departamendua", "Morazán"],
            [:svpa, "La Paz departamendua", "La Paz"],
            [:svsa, "Santa Ana departamendua", "Santa Ana"],
            [:svsm, "San Miguel departamendua", "San Miguel"],
            [:svso, "Sonsonate departamendua", "Sonsonate"],
            [:svss, "San Salvador departamendua", "San Salvador"],
            [:svsv, "San Vicente departamendua", "San Vicente"],
            [:svun, "La Unión departamendua", "La Unión"],
            [:svus, "Usulután departamendua", "Usulután"],
          ])
          patch_subdivisions(:fi, [
            [:svah, "Ahuachapánin departmentti", "Ahuachapánin"],
            [:svca, "Cabañasn departmentti", "Cabañasn"],
            [:svcu, "Cuscatlánin departmentti", "Cuscatlánin"],
            [:svli, "La Libertadin departmentti", "La Libertadin"],
            [:svmo, "Morazánin departmentti", "Morazánin"],
            [:svpa, "La Pazin depatermentti", "La Pazin"],
            [:svsa, "Santa Anan departmentti", "Santa Anan"],
            [:svsm, "San Miguelin departmentti", "San Miguelin"],
            [:svss, "San Salvadorin departmentti", "San Salvadorin"],
            [:svsv, "San Vicenten departementti", "San Vicenten"],
            [:svus, "Usulutánin departmentti", "Usulutánin"],
          ])
          patch_subdivisions(:fr, [
            [:svah, "département d’Ahuachapán", "Ahuachapán"],
            [:svca, "département de Cabañas", "Cabañas"],
            [:svch, "département de Chalatenango", "Chalatenango"],
            [:svcu, "département de Cuscatlán", "Cuscatlán"],
            [:svmo, "département de Morazán", "Morazán"],
            [:svpa, "département de La Paz", "La Paz"],
            [:svsa, "département de Santa Ana", "Santa Ana"],
            [:svsm, "département de San Miguel", "San Miguel"],
            [:svso, "département de Sonsonate", "Sonsonate"],
            [:svss, "département de San Salvador", "San Salvador"],
            [:svsv, "département de San Vicente", "San Vicente"],
            [:svun, "département de La Unión", "La Unión"],
            [:svus, "département d’Usulután", "Usulután"],
          ])
          patch_subdivisions(:gu, [
            [:svah, "આહુચપન વિભાગ", "આહુચપન"],
            [:svca, "કેબાનાસ વિભાગ", "કેબાનાસ"],
            [:svcu, "કુસ્કાટલાન વિભાગ", "કુસ્કાટલાન"],
            [:svli, "લા લિબરટૅડ વિભાગ", "લા લિબરટૅડ"],
            [:svmo, "મોરાઝાન વિભાગ", "મોરાઝાન"],
            [:svpa, "લા પાઝ વિભાગ", "લા પાઝ"],
            [:svsa, "સાંતા એના વિભાગ", "સાંતા એના"],
            [:svsm, "સેન મિગ્યુએલ વિભાગ", "સેન મિગ્યુએલ"],
            [:svso, "સોન્સોનેટ વિભાગ", "સોન્સોનેટ"],
            [:svss, "સાન સલ્વાડોર વિભાગ", "સાન સલ્વાડોર"],
            [:svsv, "સેન વિસેન્ટ વિભાગ", "સેન વિસેન્ટ"],
            [:svus, "ઉસુલુટન વિભાગ", "ઉસુલુટન"],
          ])
          patch_subdivisions(:hi, [
            [:svsa, "सानता-आना प्रदेश", "सानता-आना"],
            [:svso, "सोनसोनाते प्रदेश", "सोनसोनाते"],
            [:svun, "ला-उनिओन प्रदेश", "ला-उनिओन"],
          ])
          patch_subdivisions(:hu, [
            [:svah, "Ahuachapán megye", "Ahuachapán"],
            [:svca, "Cabañas megye", "Cabañas"],
            [:svch, "Chalatenango megye", "Chalatenango"],
            [:svcu, "Cuscatlán megye", "Cuscatlán"],
            [:svli, "La Libertad megye", "La Libertad"],
            [:svmo, "Morazán megye", "Morazán"],
            [:svpa, "La Paz megye", "La Paz"],
            [:svsa, "Santa Ana megye", "Santa Ana"],
            [:svsm, "San Miguel megye", "San Miguel"],
            [:svso, "Sonsonate megye", "Sonsonate"],
            [:svss, "San Salvador megye", "San Salvador"],
            [:svsv, "San Vicente megye", "San Vicente"],
            [:svun, "La Unión megye", "La Unión"],
            [:svus, "Usulután megye", "Usulután"],
          ])
          patch_subdivisions(:id, [
            [:svah, "Departemen Ahuachapán", "Ahuachapán"],
            [:svca, "Departemen Cabañas", "Cabañas"],
            [:svch, "Departemen Chalatenango", "Chalatenango"],
            [:svcu, "Departemen Cuscatlán", "Cuscatlán"],
            [:svli, "Departemen La Libertad", "La Libertad"],
            [:svmo, "Departemen Morazán", "Morazán"],
            [:svpa, "Departemen La Paz", "La Paz"],
            [:svsa, "Departemen Santa Ana", "Santa Ana"],
            [:svsm, "Departemen San Miguel", "San Miguel"],
            [:svso, "Departemen Sonsonate", "Sonsonate"],
            [:svss, "Departemen San Salvador", "San Salvador"],
            [:svsv, "Departemen San Vicente", "San Vicente"],
            [:svun, "Departemen La Unión", "La Unión"],
            [:svus, "Departemen Usulután", "Usulután"],
          ])
          patch_subdivisions(:it, [
            [:svah, "dipartimento di Ahuachapán", "Ahuachapán"],
            [:svca, "dipartimento di Cabañas", "Cabañas"],
            [:svch, "dipartimento di Chalatenango", "Chalatenango"],
            [:svcu, "dipartimento di Cuscatlán", "Cuscatlán"],
            [:svli, "dipartimento di La Libertad", "La Libertad"],
            [:svmo, "dipartimento di Morazán", "Morazán"],
            [:svsa, "dipartimento di Santa Ana", "Santa Ana"],
            [:svsm, "dipartimento di San Miguel", "San Miguel"],
            [:svso, "dipartimento di Sonsonate", "Sonsonate"],
            [:svss, "dipartimento di San Salvador", "San Salvador"],
            [:svsv, "dipartimento di San Vicente", "San Vicente"],
            [:svun, "dipartimento di La Unión", "La Unión"],
            [:svus, "dipartimento di Usulután", "Usulután"],
          ])
          patch_subdivisions(:ja, [
            [:svah, "アワチャパン県", "アワチャパン"],
            [:svca, "カバーニャス県", "カバーニャス"],
            [:svch, "チャラテナンゴ県", "チャラテナンゴ"],
            [:svcu, "クスカトラン県", "クスカトラン"],
            [:svli, "ラリベルタ県 (エルサルバドル)", "ラリベルタ"],
            [:svmo, "モラサン県", "モラサン"],
            [:svpa, "ラ・パス県 (エル・サルバドル)", "ラ・パス"],
            [:svsa, "サンタ・アナ県", "サンタ・アナ"],
            [:svsm, "サンミゲル県", "サンミゲル"],
            [:svso, "ソンソナーテ県", "ソンソナーテ"],
            [:svss, "サン・サルバドル県", "サン・サルバドル"],
            [:svsv, "サン・ビセンテ県", "サン・ビセンテ"],
            [:svun, "ラ・ウニオン県", "ラ・ウニオン"],
            [:svus, "ウスルタン県", "ウスルタン"],
          ])
          patch_subdivisions(:kn, [
            [:svah, "ಅಹುಚಪಾನ್ ಇಲಾಖೆ", "ಅಹುಚಪಾನ್"],
            [:svca, "ಕ್ಯಾಬಾನಾಸ್ ಇಲಾಖೆ", "ಕ್ಯಾಬಾನಾಸ್"],
            [:svcu, "ಕುಸ್ಕಟಾನ್ ಇಲಾಖೆ", "ಕುಸ್ಕಟಾನ್"],
            [:svli, "ಲಾ ಲಿಬರ್ಟಾಡ್ ಇಲಾಖೆ", "ಲಾ ಲಿಬರ್ಟಾಡ್"],
            [:svmo, "ಮೊರಾಜನ್ ಇಲಾಖೆ", "ಮೊರಾಜನ್"],
            [:svpa, "ಲಾ ಪಾಜ್ ಇಲಾಖೆ", "ಲಾ ಪಾಜ್"],
            [:svsa, "ಸಾಂಟಾ ಅನಾ ಇಲಾಖೆ", "ಸಾಂಟಾ ಅನಾ"],
            [:svsm, "ಸ್ಯಾನ್ ಮಿಗುಯೆಲ್ ಇಲಾಖೆ", "ಸ್ಯಾನ್ ಮಿಗುಯೆಲ್"],
            [:svso, "ಸನ್ಸೊನೇಟ್ ಇಲಾಖೆ", "ಸನ್ಸೊನೇಟ್"],
            [:svss, "ಸ್ಯಾನ್ ಸಾಲ್ವಡಾರ್ ಇಲಾಖೆ", "ಸ್ಯಾನ್ ಸಾಲ್ವಡಾರ್"],
            [:svsv, "ಸ್ಯಾನ್ ವಿಸೆಂಟೆ ಇಲಾಖೆ", "ಸ್ಯಾನ್ ವಿಸೆಂಟೆ"],
            [:svus, "ಯುಸುಲ್ಯುಟಾನ್ ಡಿಪಾರ್ಟ್ಮೆಂಟ್", "ಯುಸುಲ್ಯುಟಾನ್"],
          ])
          patch_subdivisions(:ko, [
            [:svah, "아우아차판 주", "아우아차판"],
            [:svca, "카바냐스 주", "카바냐스"],
            [:svch, "찰라테낭고 주", "찰라테낭고"],
            [:svcu, "쿠스카틀란 주", "쿠스카틀란"],
            [:svli, "라리베르타드 주", "라리베르타드"],
            [:svmo, "모라산 주", "모라산"],
            [:svpa, "라파스 주", "라파스"],
            [:svsa, "산타아나 주", "산타아나"],
            [:svsm, "산미겔 주", "산미겔"],
            [:svso, "손소나테 주", "손소나테"],
            [:svss, "산살바도르 주", "산살바도르"],
            [:svsv, "산비센테 주", "산비센테"],
            [:svun, "라우니온 주", "라우니온"],
            [:svus, "우술루탄 주", "우술루탄"],
          ])
          patch_subdivisions(:lt, [
            [:svah, "Auačapano departamentas", "Auačapano"],
            [:svca, "Kabanjaso departamentas", "Kabanjaso"],
            [:svch, "Čalatenango departamentas", "Čalatenango"],
            [:svcu, "Kuskatlano departamentas", "Kuskatlano"],
            [:svli, "La Libertado departamentas", "La Libertado"],
            [:svmo, "Morasano departamentas", "Morasano"],
            [:svpa, "La Paso departamentas", "La Paso"],
            [:svsa, "Santa Anos departamentas", "Santa Anos"],
            [:svsm, "San Migelio departamentas", "San Migelio"],
            [:svso, "Sonsonatės departamentas", "Sonsonatės"],
            [:svss, "San Salvadoro departamentas", "San Salvadoro"],
            [:svsv, "San Visentės departamentas", "San Visentės"],
            [:svun, "La Uniono departamentas", "La Uniono"],
            [:svus, "Usulutano departamentas", "Usulutano"],
          ])
          patch_subdivisions(:lv, [
            [:svah, "Avačapanas departaments", "Avačapanas"],
            [:svca, "Kabanjasas departaments", "Kabanjasas"],
            [:svcu, "Kuskatlanas departaments", "Kuskatlanas"],
            [:svli, "Lalibertadas departaments", "Lalibertadas"],
            [:svmo, "Morasanas departaments", "Morasanas"],
            [:svpa, "Lapaso departaments", "Lapaso"],
            [:svsa, "Santaanas departaments", "Santaanas"],
            [:svsm, "Sanmigelas departaments", "Sanmigelas"],
            [:svso, "Sonsonates departaments", "Sonsonates"],
            [:svss, "Sansalvadoras departaments", "Sansalvadoras"],
            [:svsv, "Sanvisentes departaments", "Sanvisentes"],
            [:svus, "Usulutanas departaments", "Usulutanas"],
          ])
          patch_subdivisions(:mr, [
            [:svah, "अहुचापान विभाग", "अहुचापान"],
            [:svca, "सेबानास विभाग", "सेबानास"],
            [:svcu, "कुस्कॅटान विभाग", "कुस्कॅटान"],
            [:svli, "ला लिबर्टाद विभाग", "ला लिबर्टाद"],
            [:svmo, "मोराझान विभाग", "मोराझान"],
            [:svpa, "ला पाझ विभाग", "ला पाझ"],
            [:svsa, "सांता आना विभाग", "सांता आना"],
            [:svsm, "सॅन मिगेल विभाग", "सॅन मिगेल"],
            [:svso, "सोंसोनेट विभाग", "सोंसोनेट"],
            [:svss, "सॅन साल्वादोर विभाग", "सॅन साल्वादोर"],
            [:svsv, "सॅन व्हिसेंटा विभाग", "सॅन व्हिसेंटा"],
            [:svus, "उसुलुटन विभाग", "उसुलुटन"],
          ])
          patch_subdivisions(:ms, [
            [:svah, "Ahuachapan Department", "Ahuachapan"],
            [:svca, "Cabañas Department", "Cabañas"],
            [:svcu, "Cuscatlan Department", "Cuscatlan"],
            [:svli, "La Libertad Department", "La Libertad"],
            [:svmo, "Morazan Department", "Morazan"],
            [:svpa, "La Paz Department", "La Paz"],
            [:svsa, "Santa Ana Department", "Santa Ana"],
            [:svsm, "San Miguel Department", "San Miguel"],
            [:svso, "Sonsonate Department", "Sonsonate"],
            [:svss, "San Salvador Department", "San Salvador"],
            [:svsv, "San Vicente Department", "San Vicente"],
            [:svus, "Usulutan Department", "Usulutan"],
          ])
          patch_subdivisions(:no, [
            [:svli, "La Libertad department", "La Libertad"],
            [:svmo, "Morazan department", "Morazan"],
            [:svpa, "La Paz department", "La Paz"],
            [:svsa, "Santa Ana department", "Santa Ana"],
            [:svsm, "San Miguel department", "San Miguel"],
            [:svso, "Sonsonate department", "Sonsonate"],
            [:svsv, "San Vincente department", "San Vincente"],
            [:svus, "Usulutan department", "Usulutan"],
          ])
          patch_subdivisions(:ro, [
            [:svah, "Departamentul Ahuachapán", "Ahuachapán"],
            [:svca, "Departamentul Cabañas", "Cabañas"],
            [:svch, "Departamentul Chalatenango", "Chalatenango"],
            [:svcu, "Departamentul Cuscatlán", "Cuscatlán"],
            [:svli, "Departamentul La Libertad", "La Libertad"],
            [:svmo, "Departamentul Morazán", "Morazán"],
            [:svpa, "Departamentul La Paz, El Salvador", "La Paz, El Salvador"],
            [:svsa, "Departamentul Santa Ana", "Santa Ana"],
            [:svsm, "Departamentul San Miguel, El Salvador", "San Miguel, El Salvador"],
            [:svso, "Departamentul Sonsonate", "Sonsonate"],
            [:svss, "Departamentul San Salvador", "San Salvador"],
            [:svsv, "Departamentul San Vicente", "San Vicente"],
            [:svun, "Departamentul La Unión", "La Unión"],
            [:svus, "Departamentul Usulután", "Usulután"],
          ])
          patch_subdivisions(:ru, [
            [:svus, "Усулутан (департамент)", "Усулутан"],
          ])
          patch_subdivisions(:si, [
            [:svah, "අහුවාචපාන් දෙපාර්තමේන්තුව", "අහුවාචපාන්"],
            [:svca, "කබානාස් දෙපාර්තමේන්තුව", "කබානාස්"],
            [:svcu, "කුස්කෙට්ලාන් දෙපාර්තමේන්තුව", "කුස්කෙට්ලාන්"],
            [:svli, "ලා ලිබරෙටඩ් දෙපාර්තමේන්තුව", "ලා ලිබරෙටඩ්"],
            [:svmo, "මොරසාන් දෙපාර්තමේන්තුව", "මොරසාන්"],
            [:svpa, "ලා ප්ලාස් දෙපාර්තමේන්තුව", "ලා ප්ලාස්"],
            [:svsa, "සැන්ටා ඇනා දෙපාර්තමේන්තුව", "සැන්ටා ඇනා"],
            [:svsm, "සැන් මිගෙල් දෙපාර්තමේන්තුව", "සැන් මිගෙල්"],
            [:svso, "සොන්සොනාටේ දෙපාර්තමේන්තුව", "සොන්සොනාටේ"],
            [:svss, "සැන් සැල්වදෝර් දෙපාර්තමේන්තුව", "සැන් සැල්වදෝර්"],
            [:svsv, "සැන් විසේන්තේ දෙපාර්තමේන්තුව", "සැන් විසේන්තේ"],
            [:svus, "උලුස්තාන් දෙපාර්තමේන්තුව", "උලුස්තාන්"],
          ])
          patch_subdivisions(:sv, [
            [:svli, "La Libertad Department", "La Libertad"],
            [:svmo, "Morazan Department", "Morazan"],
            [:svsa, "Santa Ana department", "Santa Ana"],
            [:svsm, "San Miguel Department", "San Miguel"],
            [:svso, "Sonsonate Department", "Sonsonate"],
            [:svsv, "San Vincente department", "San Vincente"],
            [:svus, "Usulutan department", "Usulutan"],
          ])
          patch_subdivisions(:ta, [
            [:svah, "குச்சாபன் துறை", "குச்சாபன்"],
            [:svca, "கபானாஸ் துறை", "கபானாஸ்"],
            [:svcu, "குசுக்காட்லான் துறை", "குசுக்காட்லான்"],
            [:svli, "லா லிபேர்ட்டட் துறை", "லா லிபேர்ட்டட்"],
            [:svmo, "மொராசன் துறை", "மொராசன்"],
            [:svpa, "லா பாஸ் துறை", "லா பாஸ்"],
            [:svsa, "சாண்டா அனா துறை", "சாண்டா அனா"],
            [:svsm, "சான் மிகுயில் துறை", "சான் மிகுயில்"],
            [:svso, "சோனிசோனட் துறை", "சோனிசோனட்"],
            [:svss, "சான் சால்வடோர் துறை", "சான் சால்வடோர்"],
            [:svsv, "சான் விஸேண்ட் துறை", "சான் விஸேண்ட்"],
            [:svus, "உஸூலுடன் துறை", "உஸூலுடன்"],
          ])
          patch_subdivisions(:te, [
            [:svah, "అహూచాపన్ డిపార్ట్మెంట్", "అహూచాపన్"],
            [:svca, "కబానాస్ డిపార్ట్మెంట్", "కబానాస్"],
            [:svcu, "కుస్కట్లాన్ డిపార్ట్మెంట్", "కుస్కట్లాన్"],
            [:svli, "లా లిబర్టాడ్ డిపార్ట్మెంట్", "లా లిబర్టాడ్"],
            [:svmo, "మోరాజన్ డిపార్ట్మెంట్", "మోరాజన్"],
            [:svpa, "లా పాజ్ డిపార్ట్మెంట్", "లా పాజ్"],
            [:svsa, "సాంటా ఆనా డిపార్ట్మెంట్", "సాంటా ఆనా"],
            [:svsm, "సాన్ మిగ్వెల్ డిపార్ట్మెంట్", "సాన్ మిగ్వెల్"],
            [:svso, "సన్సోనేట్ డిపార్ట్మెంట్", "సన్సోనేట్"],
            [:svss, "సాన్ సాల్వడార్ డిపార్ట్మెంట్", "సాన్ సాల్వడార్"],
            [:svsv, "సాన్ విసెంటి డిపార్ట్మెంట్", "సాన్ విసెంటి"],
            [:svus, "ఉసులుటాన్ డిపార్ట్మెంట్", "ఉసులుటాన్"],
          ])
          patch_subdivisions(:tr, [
            [:svah, "Ahuachpan Departmanı", "Ahuachpan"],
            [:svca, "Cabanas Departmanı", "Cabanas"],
            [:svcu, "Cuscatian Departmanı", "Cuscatian"],
            [:svli, "La Libertad Departmanı", "La Libertad"],
            [:svmo, "Morazan Departmanı", "Morazan"],
            [:svpa, "Le Paz Departmanı", "Le Paz"],
            [:svsa, "Santa Ana Departmanı", "Santa Ana"],
            [:svsm, "San Miguel Departmanı", "San Miguel"],
            [:svso, "Sonsonate Departmanı", "Sonsonate"],
            [:svsv, "San Vicente Departmanı", "San Vicente"],
            [:svus, "Usulutan Departmanı", "Usulutan"],
          ])
          patch_subdivisions(:uk, [
            [:svah, "Регіон Ауачапан", "Ауачапан"],
            [:svca, "Регіон Кабаньяс", "Кабаньяс"],
            [:svcu, "Регіон Кускатлан", "Кускатлан"],
            [:svli, "Муніципалітет Ла-Лібертад", "Ла-Лібертад"],
            [:svpa, "Департамент Ла-Пас", "Ла-Пас"],
            [:svsa, "Регіон Санта-Ана", "Санта-Ана"],
            [:svsm, "Регіон Сан-Мігель", "Сан-Мігель"],
            [:svso, "Регіон Сонсонате", "Сонсонате"],
            [:svsv, "Регіон Сан-Вісенте", "Сан-Вісенте"],
            [:svus, "Регіон Усулутан", "Усулутан"],
          ])
          patch_subdivisions(:ur, [
            [:svah, "اہواشاپان محکمہ", "اہواشاپان"],
            [:svca, "کابانیاس محکمہ", "کابانیاس"],
            [:svch, "شالاتنانگو محکمہ", "شالاتنانگو"],
            [:svcu, "کوسکاتلان محکمہ", "کوسکاتلان"],
            [:svli, "لا لیبیرتاڈ دیپارٹمنٹ", "لا لیبیرتاڈ"],
            [:svmo, "مورازان محکمہ", "مورازان"],
            [:svpa, "لا پاز ڈیپارٹمنٹ", "لا پاز"],
            [:svsa, "سانتا آنا محکمہ", "سانتا آنا"],
            [:svsm, "سان میگیل محکمہ", "سان میگیل"],
            [:svso, "سونسوناتے محکمہ", "سونسوناتے"],
            [:svss, "سان سیلواڈور محکمہ", "سان سیلواڈور"],
            [:svsv, "سان ویسینتے محکمہ", "سان ویسینتے"],
            [:svun, "لا یونیون ڈیپارٹمنٹ", "لا یونیون"],
            [:svus, "اوسولوتآن محکمہ", "اوسولوتآن "],
          ])
          patch_subdivisions(:vi, [
            [:svah, "Khu vực hành chính Ahuachapán", "Ahuachapán"],
            [:svca, "Khu vực hành chính Cabanas", "Cabanas"],
            [:svcu, "Khu vực hành chính Cuscatlán", "Cuscatlán"],
            [:svli, "Khu vực hành chính La Libertad", "La Libertad"],
            [:svmo, "Khu vực hành chính Morazán", "Morazán"],
            [:svpa, "Tỉnh La Paz", "La Paz"],
            [:svsa, "Khu vực hành chính Santa Ana", "Santa Ana"],
            [:svsm, "Khu vực hành chính San Miguel", "San Miguel"],
            [:svso, "Khu vực hành chính Sonsonate", "Sonsonate"],
            [:svss, "Khu vực hành chính San Salvador", "San Salvador"],
            [:svsv, "Khu vực hành chính San Vicente", "San Vicente"],
            [:svus, "Khu vực hành chính Usulután", "Usulután"],
          ])
          patch_subdivisions(:zh, [
            [:svah, "阿瓦查潘省", "阿瓦查潘"],
            [:svca, "卡瓦尼亚斯省", "卡瓦尼亚斯"],
            [:svch, "查拉特南戈省", "查拉特南戈"],
            [:svcu, "库斯卡特兰省", "库斯卡特兰"],
            [:svli, "拉利伯塔德省", "拉利伯塔德"],
            [:svmo, "莫拉桑省", "莫拉桑"],
            [:svpa, "拉巴斯省", "拉巴斯"],
            [:svsa, "圣安娜省", "圣安娜"],
            [:svsm, "圣米格尔省", "圣米格尔"],
            [:svso, "松索纳特省", "松索纳特"],
            [:svss, "聖薩爾瓦多省", "聖薩爾瓦多"],
            [:svsv, "圣维森特省", "圣维森特"],
            [:svun, "拉乌尼翁省", "拉乌尼翁"],
            [:svus, "乌苏卢坦省", "乌苏卢坦"],
          ])

          # Thai date formats use the `G` field ("era name") in their date formats.
          # But I18n.l has no support for era names.
          # However in practice, years from both the Gregorian and Thai Solar Calendars are commonly used in Thailand, without any disambiguating era names
          # Therefore, we'll remove the era name from the Thai date formats that we use.
          patch_file(:th, "calendars.yml", [:calendars, :gregorian, :additional_formats, :yMMMM], "MMMM G y", "MMMM y")
          patch_file(:th, "calendars.yml", [:calendars, :gregorian, :formats, :date, :full, :pattern], "EEEEที่ d MMMM G y", "EEEEที่ d MMMM y")
          patch_file(:th, "calendars.yml", [:calendars, :gregorian, :formats, :date, :long, :pattern], "d MMMM G y", "d MMMM y")

          # Lao date formats use the `G` field ("era name") in their date formats.
          # But I18n.l has no support for era names.
          # AFAICT, Gregorian years are commonly used in Laos, without any disambiguating era names
          # Therefore, we'll remove the era name from the Lao date formats that we use.
          patch_file(:lo, "calendars.yml", [:calendars, :gregorian, :formats, :date, :full, :pattern], "EEEE ທີ d MMMM G y", "EEEE ທີ d MMMM y")

          # Swahili in Kenya (sw-KE) date formats use the `G` field ("era name") in their date formats.
          # But I18n.l has no support for era names.
          # AFAICT, Gregorian dates are commonly used in Kenya, without any era indicator.
          # Therefore, we'll remove the era name from the sw-KE date formats that we use.
          patch_file(:"sw-KE", "calendars.yml", [:calendars, :gregorian, :formats, :date, :full, :pattern], "EEEE, d MMMM y G", "EEEE, d MMMM y")
          patch_file(:"sw-KE", "calendars.yml", [:calendars, :gregorian, :formats, :date, :long, :pattern], "d MMMM y G", "d MMMM y")

          # CLDR changed the name to something super long and seemingly redundant.
          # https://unicode-org.atlassian.net/browse/CLDR-15867
          patch_territories(:bn, [
            [:MO, "ম্যাকাও এসএআর চীনা চীনা (ম্যাকাও এসএআর চীনা) চীনা (ঐতিহ্যবাহী, ম্যাকাও এসএআর চীনা) অঞ্চল: ম্যাকাও এসএআর চীন", "ম্যাকাও এসএআর চীনা"],
          ])

          patch_territories(:da, [
            # "De tidligere Nederlandske Antiller" means "the former Netherlands Antilles", which is country code AN
            [:BQ, "De tidligere Nederlandske Antiller", "Caribisk Nederlandene"],
            # (North and South) Holland are two of the many provinces in NL; the whole country is the Netherlands
            [:NL, "Holland", "Holland (Nederlandene)"],
            # This name is technically correct, but overly long
            [:TF, "De Franske Besiddelser i Det Sydlige Indiske Ocean og Antarktis", "Franske sydlige territorier"],
          ])

          patch_territories(:de, [
            # This name is correct, but overly long
            [:TF, "Französische Süd- und Antarktisgebiete", "Französische Südgebiete"],
          ])

          patch_territories(:en, [
            # UN M49 uses 830 for "Channel Islands", but ISO 3166-1 does not, so CLDR is missing this code
            # https://en.wikipedia.org/wiki/UN_M49#cite_note-7
            [:"830", nil, "Channel Islands"],
            # CLDR added Sark in version 44.  We need to backport this until we upgrade to that version.
            [:CQ, nil, "Sark"],
            # The U.N. now uses Türkiye for the country formerly recognized as Turkey:
            # https://turkiye.un.org/en/184798-turkeys-name-changed-t%C3%BCrkiye
            [:TR, "Turkey", "Türkiye"],
          ])

          patch_territories(:fi, [
            # GB is the ISO code for the United Kingdom of Great Britain _and_ Northern Ireland
            # (Northern Ireland is part of the United Kingdom, but not part of Great Britain).
            [:GB, "Iso-Britannia", "Yhdistynyt kuningaskunta"],
          ])

          patch_territories(:fr, [
            # UN M49 uses 830 for "Channel Islands", but ISO 3166-1 does not, so CLDR is missing this code
            # https://en.wikipedia.org/wiki/UN_M49#cite_note-7
            [:"830", nil, "Îles Anglo-Normandes"],
            # CLDR added Sark in version 44.  We need to backport this until we upgrade to that version.
            [:CQ, nil, "Sercq"],
          ])

          patch_territories(:it, [
            # Swaziland changed its name to eSwatini in 2018
            [:SZ, "Swaziland", "eSwatini"],
          ])

          # CLDR changed the name to Latin characters
          patch_territories(:mr, [
            [:CI, "Côte d’Ivoire", "आयव्हरी कोस्ट"],
          ])

          # Prefer the phrasing "Hong Kong SAR" and "Macau SAR"
          patch_territories(:zh, [
            [:HK, "中国香港特别行政区", "香港特别行政区"],
            [:MO, "中国澳门特别行政区", "澳门特别行政区"],
          ])
          patch_territories(:"zh-Hant", [
            [:HK, "中國香港特別行政區", "香港特別行政區"],
            [:MO, "中國澳門特別行政區", "澳門特別行政區"],
          ])

          # Should use capitalized letters for territories in UI list context, by default.
          patch_file(:root, "context_transforms.yml", [:context_transforms, :territory, :ui_list_or_menu], nil, "titlecase_first_word", allow_file_creation: true)

          patch_sar_china_suffix

          # We only require a subset of unit translations so units.yml is patched here
          patch_units

          # CLDR wants to use 999 for `ZZ` (Unknown Region), but we use that for `Rest of World`
          patch_cldr_level_file("country_codes.yml", [:country_codes, :ZZ, :numeric], "999", "000")

          patch_cldr_level_file_delete_keys("country_codes.yml", [:country_codes], ["CP", "DG"])

          # `ruby-cldr` exports the following keys that overlap their numeric values with other valid countries:
          #   - BU (Burma) and MM (Myanmar) are the same country, Myanmar is the new name used by the current government.
          #   - ZR and CD are the same country, ZR is the old code.
          #   - CS is the old code for Czechoslovakia, no longer exists since 1993.
          #   - YU is the State Union of Serbia and Montenegro, ceased to exist in 2006.
          #   - TP and TL are the same country, TP is the old name.
          # For more information message Christian Jaekl or Devan Andersen.
          patch_cldr_level_file_delete_keys("country_codes.yml", [:country_codes], ["BU", "CS", "TP", "YU", "ZR"])

          patch_currency_formats

          # Keep unconfirmed currency format in BO for consistency with patch made in CurrencyPatches#patch_currency_formats
          patch_file(:bo, "numbers.yml", [:numbers, :latn, :formats, :currency, :patterns, :default], nil, "¤ #,##0.00")

          # Delete "This is not a translation" values in IG
          values_to_patch = YAML.load_file("data/cldr/locales/ig/currencies.yml")["ig"]["currencies"]["LSL"]
          values_to_patch.each do |key, value|
            raise "ig.currencies.LSL.#{key} is no longer 'This is not a translation'." unless value == "This is not a translation"
          end
          patch_file_delete_keys(:ig, "currencies.yml", [:currencies], [:LSL])

          # Add missing '%{count}' in IT
          patch_file(:it, "units.yml", [:units, :unit_length, :long, :volume_fluid_ounce, :one], "oncia liquida", "%{count} oncia liquida")

          sort_cldr_files

          copy_zh_locales
        end

        private

        # Smartling doesn't support locale names 'zh-Hans', 'zh-Hant', and 'zh-Hant-HK'.
        # To be compatible with Smartling, we use 'zh-CN' where we mean 'zh-Hans',
        # 'zh-TW' where we mean 'zh-Hant', and 'zh-HK' where we mean 'zh-Hant-HK'
        # When client code looks up CLDR data using I18n.t(), we want use of 'zh-CN'
        # to return the CLDR data for 'zh-Hans', etc. So, we copy those entries over here.
        def copy_zh_locales
          copy_locale("zh-Hans", "zh-CN")
          copy_locale("zh-Hant-HK", "zh-HK")
          copy_locale("zh-Hant", "zh-TW")
        end

        def copy_locale(source, target)
          puts "Copy locale #{source} to #{target}..."
          FileUtils.mkdir_p(File.join(Worldwide::Paths::CLDR_ROOT, "locales", target.to_s))

          files_to_patch = Dir[File.join(Worldwide::Paths::CLDR_ROOT, "locales", source, "*.yml")]
          raise "No CLDR files found for #{source}" if files_to_patch.empty?

          files_to_patch.each do |source_file_name|
            target_file_name = source_file_name.sub(source, target) # TODO: Fix this bug; It could replace the parent directory names
            data = YAML.safe_load(File.open(source_file_name), permitted_classes: [Symbol])
            data[target] = data[source]
            data.delete(source)
            File.write(target_file_name, data.to_yaml)
          end

          files_to_patch = Dir[File.join(Worldwide::Paths::CLDR_ROOT, "locales", source, "plurals.rb")]
          files_to_patch.each do |source_file_name|
            target_file_name = source_file_name.sub(source, target) # TODO: Fix this bug; It could replace the parent directory names
            content = File.read(source_file_name).gsub(
              ":'#{source.tr("-", "_")}'",
              ":'#{target.tr("-", "_")}'",
            )
            File.write(target_file_name, content)
          end

          # The copied locale should have the same ancestors / fallback chain that the source locale has.
          # The source locale might have an overidden parent locale. If so, we want to copy that override.
          # Otherwise, we want the parent of the source locale to be the parent of this new locale.
          parent_locales_path = File.join(Worldwide::Paths::CLDR_ROOT, "parent_locales.yml")
          contents = YAML.load_file(parent_locales_path)
          parent_override = contents[source]
          parent_override ||= begin
            chopped_source_locale = I18n::Locale::Tag.tag(source).parents.first.to_s
            chopped_target_locale = I18n::Locale::Tag.tag(target).parents.first.to_s
            chopped_source_locale if chopped_source_locale != chopped_target_locale
          end
          if parent_override
            patch_cldr_level_file("parent_locales.yml", [target], nil, parent_override)
            SortYaml.sort_file(parent_locales_path, output_filename: parent_locales_path)
          end
        end

        def sort_cldr_files
          puts("🔀 Sorting the keys in the patched files")
          Dir.glob(File.join(["data", "cldr", "**", "*.yml"])).sum do |filepath|
            next 0 if filepath.start_with?("data/cldr/transforms")
            next 0 if filepath.start_with?("data/cldr/metazones.yml")

            # These files are sorted non-alphabetically, so we don't want to sort them.
            next 0 if filepath.end_with?("calendars.yml")
            next 0 if filepath.end_with?("delimiters.yml")
            next 0 if filepath.end_with?("lists.yml")

            file_changed = SortYaml.sort_file(filepath, output_filename: filepath)
            file_changed ? 1 : 0
          end
        end

        # How one refers to Macau and Hong Kong is contentious
        # For now, we want to use the "SAR" suffix, not the "SAR China" suffix
        def patch_sar_china_suffix
          # Remove the "China" suffix from "SAR China"
          patch_territories(:en, [
            [:HK, "Hong Kong SAR China", "Hong Kong SAR"],
            [:MO, "Macao SAR China", "Macao SAR"],
          ])
          patch_subdivisions(:en, [
            [:cn91, "Hong Kong SAR China", "Hong Kong SAR"],
            [:cn92, "Macao SAR China", "Macao SAR"],
            [:HK, "Hong Kong SAR China", "Hong Kong SAR"],
            [:MO, "Macao SAR China", "Macao SAR"],
          ])

          # Add the "SAR" suffix to the keys that are missing it
          patch_subdivisions(:en, [
            [:cnhk, "Hong Kong", "Hong Kong SAR"],
            [:cnmo, "Macau", "Macao SAR"],
          ])
        end

        def patch_units
          puts("📐 Patching the units.yml CLDR files")
          measurement_keys = Worldwide.units.measurement_keys.values.uniq.map(&:to_s)
          units_filepaths = Dir.glob(File.join(["data", "cldr", "locales", "*", "units.yml"]))
          raise NotNeededError, "No CLDR units files found to patch." if units_filepaths.empty?

          files_changed = units_filepaths.sum do |file_path|
            locale = File.basename(File.dirname(file_path))
            paths_to_keep = [
              [locale, "units", "unit_length", "long"],
              [locale, "units", "unit_length", "short"],
            ].flat_map { |path| [path].product(measurement_keys).map(&:flatten) }

            file_path = "data/cldr/locales/#{locale}/units.yml"
            file_changed = patch_units_file(file_path, paths_to_keep)
            file_changed ? 1 : 0
          end
          raise NotNeededError, "Patching the unit CLDR files made no changes." if files_changed == 0
        end

        def replace_locale(text, source_locale, destination_locale)
          result = text

          ruby_cldr_regex = /:(['\"])#{source_locale}\1/
          match = result.match(ruby_cldr_regex)
          if match
            quote = match[1]
            result = result.gsub(
              ruby_cldr_regex,
              ":#{quote}#{destination_locale}#{quote}",
            )
          end

          result
        end

        def copy_file(source_locale, destination_locale, file_name)
          source_path_name = "data/cldr/locales/#{source_locale}/#{file_name}"
          destination_path_name = "data/cldr/locales/#{destination_locale}/#{file_name}"
          existing_content = File.read(source_path_name)

          modified_content = replace_locale(existing_content, source_locale, destination_locale)
          content_in_destination = File.read(destination_path_name)

          if modified_content != content_in_destination
            File.write(destination_path_name, modified_content)
          elsif upgrade?
            raise NotNeededError, "`copy_file(#{source_locale.inspect}, #{destination_locale.inspect}, #{file_name.inspect})` made no changes."
          end
        end

        def patch_cldr_level_file(file_name, key_path, existing_value, value, **options)
          file_path = "data/cldr/#{file_name}"
          patch_yaml_file(file_path, key_path, existing_value, value, **options)
        end

        def patch_cldr_level_file_delete_keys(file_name, keys_path, keys_to_delete)
          path_name = "data/cldr/#{file_name}"
          source_content = File.read(path_name)
          new_contents = delete_yaml_keys(source_content, keys_path, keys_to_delete)
          File.write(path_name, new_contents)
        end

        def patch_file(locale, file_name, key_path, existing_value, value, **options) # rubocop:disable Metrics/ParameterLists
          i18n_resolved_value = existing_value ? I18n.with_locale(locale) { Worldwide::Cldr.t(key_path.join(".")) } : nil
          raise NotNeededError, "Asked to patch `#{key_path.join(".")}` in #{locale} with `#{value}`, but that is already the resolved value of `#{key_path.join(".")}`." if i18n_resolved_value == value
          raise NotNeededError, "Asked to patch `#{key_path.join(".")}` in #{locale} `#{existing_value}` -> `#{value}`, but the existing resolved value is `#{i18n_resolved_value}`." if i18n_resolved_value != existing_value

          file_path = "data/cldr/locales/#{locale}/#{file_name}"
          patch_yaml_file(file_path, [locale, *key_path], existing_value, value, **options)
        end

        def patch_units_file(file_path, paths_to_keep)
          return false unless File.exist?(file_path)

          source_content = File.read(file_path)
          flattened = FlattenHash.run(YAML.safe_load(source_content, permitted_classes: [Symbol]))
          filtered = flattened.select { |key, _value| paths_to_keep.any? { |path| path == key[0...path.size] } }
          if Util.blank?(filtered)
            File.delete(file_path)
            return true
          end
          # units.yml is malformed and should use %{count} instead of {0}
          modified = filtered.transform_values { |value| value.gsub("{0}", "%{count}") }
          modified = modified.sort.to_h

          new_contents = UnflattenHash.run(modified).to_yaml
          File.write(file_path, new_contents)

          flattened != modified
        end

        def patch_all_delete_keys(file_name, keys_path, keys_to_delete)
          filepaths = Dir.glob(File.join(["data", "cldr", "*", file_name]))
          files_changed = filepaths.sum do |filepath|
            locale = File.basename(File.dirname(filepath))
            begin
              patch_file_delete_keys(locale, file_name, keys_path, keys_to_delete)
            rescue NotNeededError
              next 0
            end
            1
          end
          raise NotNeededError, "Deleting #{keys_to_delete.inspect} keys from under `#{keys_path.join(".")}` in all `#{file_name}` files made no changes." if files_changed == 0
        end

        def patch_file_delete_keys(locale, file_name, keys_path, keys_to_delete)
          path_name = "data/cldr/locales/#{locale}/#{file_name}"
          source_content = File.read(path_name)
          new_contents = delete_yaml_keys(source_content, [locale, *keys_path], keys_to_delete)
          File.write(path_name, new_contents)
        end

        def patch_subdivisions(locale, patches, **options)
          patches.each_with_index do |(key, existing_name, new_name), index|
            this_patch_options = options.reject { |key, _value| key == :allow_file_creation && index > 0 } # Only need to create the file for the first patch.
            patch_file(locale, "subdivisions.yml", [:subdivisions, key], existing_name, new_name, **this_patch_options)
          end
        end

        def patch_territories(locale, patches)
          patches.each do |key, existing_name, new_name|
            patch_file(locale, "territories.yml", [:territories, key], existing_name, new_name)
          end
        end

        def patch_yaml(source_content, key_path, existing_value, value)
          key_path = key_path.map(&:to_s)
          data = YAML.safe_load(source_content)
          flat_data = FlattenHash.run(data)

          if flat_data.key?(key_path)
            raise NotNeededError, "Asked to patch `#{key_path.join(".")}` with `#{value}`, but that is already the value of `#{key_path.join(".")}`." if flat_data[key_path] == value
            raise NotNeededError, "Asked to patch `#{key_path.join(".")}` from `#{existing_value}` to `#{value}`, but its value is currently `#{flat_data[key_path]}`." if flat_data[key_path] != existing_value
          elsif !existing_value.nil?
            raise NotNeededError, "Asked to patch `#{key_path.join(".")}` with `#{value}`, but that key doesn't exist."
          end

          flat_data[key_path] = value
          UnflattenHash.run(flat_data).to_yaml
        end

        def patch_yaml_file(file_path, key_path, existing_value, value, allow_file_creation: nil)
          source_content = if File.exist?(file_path)
            raise NotNeededError, "Asked to patch `#{file_path}` (`#{key_path.join(".")}` with `#{value}`), but `allow_file_creation` was set unnecessarily." if allow_file_creation

            File.read(file_path)
          else
            raise NotNeededError, "Asked to patch `#{file_path}` (`#{key_path.join(".")}` with `#{value}`), but that file doesn't exist." unless allow_file_creation

            "---\n{}" # Empty YAML file.
          end
          new_contents = patch_yaml(source_content, key_path, existing_value, value)
          File.write(file_path, new_contents)
        rescue StandardError
          puts("Had trouble patching `#{file_path}`.")
          raise
        end

        def delete_yaml_keys(source_content, keys_path, keys_to_delete)
          data = YAML.safe_load(source_content)
          parent = begin
            keys_path.map(&:to_s).inject(data, :fetch)
          rescue KeyError
            raise NotNeededError, "Asked to delete keys from `#{keys_path.join(".")}`, but it doesn't exist."
          end

          if parent
            keys_to_delete.map(&:to_s).each do |delete_key|
              unless parent.key?(delete_key)
                raise NotNeededError, "Asked to delete `#{delete_key}` from `#{keys_path.join(".")}`, but it doesn't exist."
              end

              parent.delete(delete_key.to_s)
            end
          end
          data.to_yaml
        end
      end
    end
  end
end

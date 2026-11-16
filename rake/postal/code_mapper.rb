# frozen_string_literal: true

require_relative "puller"

# For some (but not all) countries, geonames.org uses different codes for zones
# (provinces, states, regions) than the ISO-3166 standard does.  CLDR and Worldwide,
# on the other hand, follow the ISO standard.  CodeMapper provides a mapping from
# the geonames code to the ISO code.

module Postal
  class CodeMapper
    def map_to_iso(country:, geonames_code:)
      return geonames_code unless MAPPING.include?(country.to_sym)

      return_code = MAPPING[country.to_sym][geonames_code.to_sym]
      return_code.nil? ? geonames_code : return_code
    end

    # map geonames_code: iso_code
    MAPPING = {
      JP: {
        "01": "JP-23", # Aichi-ken
        "02": "JP-05", # Akita-ken
        "03": "JP-02", # Aomori-ken
        "04": "JP-12", # Chiba-ken
        "05": "JP-38", # Ehime-ken
        "06": "JP-18", # Fukui-ken
        "07": "JP-40", # Fukuoka-ken
        "08": "JP-07", # Fukushima-ken
        "09": "JP-21", # Gifu-ken
        "10": "JP-10", # Gunma-ken
        "11": "JP-34", # Hiroshima-ken
        "12": "JP-01", # Hokkai-dou
        "13": "JP-28", # Hyougo-ken
        "14": "JP-08", # Ibaraki-ken
        "15": "JP-17", # Ishikawa-ken
        "16": "JP-03", # Iwate-ken
        "17": "JP-37", # Kagawa-ken
        "18": "JP-46", # Kagoshima-ken
        "19": "JP-14", # Kanagawa-ken
        "20": "JP-39", # Kochi-ken
        "21": "JP-43", # Kumamoto-ken
        "22": "JP-26", # Kyouto-fu
        "23": "JP-24", # Mie-ken
        "24": "JP-04", # Miyagi-ken
        "25": "JP-45", # Miyazaki-ken
        "26": "JP-20", # Nagano-ken
        "27": "JP-42", # Nagasaki-ken
        "28": "JP-29", # Nara-ken
        "29": "JP-15", # Niigata-ken
        "30": "JP-44", # Ooita-ken
        "31": "JP-33", # Okayama-ken
        "32": "JP-27", # Oosaka-fu
        "33": "JP-41", # Saga-ken
        "34": "JP-11", # Saitama-ken
        "35": "JP-25", # Shiga-ken
        "36": "JP-32", # Shimane-ken
        "37": "JP-22", # Shizuoka-ken
        "38": "JP-09", # Tochigi-ken
        "39": "JP-36", # Tokushima-ken
        "40": "JP-13", # Toukyou-to
        "41": "JP-31", # Tottori-ken
        "42": "JP-16", # Toyama-ken
        "43": "JP-30", # Wakayama-ken
        "44": "JP-06", # Yamagata-ken
        "45": "JP-35", # Yamaguchi-ken
        "46": "JP-19", # Yamanashi-ken
        "47": "JP-47", # Okinawa-ken
      },
      KR: {
        "01": "KR-49", # Jeju
        "03": "KR-45", # Jeonbuk
        "05": "KR-43", # Chungcheongbuk
        "06": "KR-42", # Gangwon
        "10": "KR-26", # Busan
        "11": "KR-11", # Seoul
        "12": "KR-28", # Incheon
        "13": "KR-41", # Geonggi
        "14": "KR-47", # Geongsangbuk
        "15": "KR-27", # Daegu
        "16": "KR-46", # Jeollanam
        "17": "KR-44", # Chungcheongnam
        "18": "KR-29", # Gwangju
        "19": "KR-30", # Daejeon
        "20": "KR-48", # Geongsangnam
        "21": "KR-31", # Ulsan
        "22": "KR-50", # Sejong
      },
      NZ: {
        "10": "CIT", # Chatham Islands
        "E7": "AUK", # Auckland
        "E8": "BOP", # Bay of Plenty
        "E9": "CAN", # Canterbury
        "F1": "GIS", # Gisborne
        "F2": "HKB", # Hawke's Bay
        "F3": "MWT", # Manawatu-Wanganui
        "F4": "MBH", # Marlborough
        "F5": "NSN", # Nelson
        "F6": "NTL", # Northland
        "F7": "OTA", # Otago
        "F8": "STL", # Southland
        "F9": "TKI", # Taranaki
        "G1": "WKO", # Waikato
        "G2": "WGN", # Wellington
        "G3": "WTC", # West Coast
        "TAS": "TAS", # Tasman
      },
      PT: {
        "02": "PT-01", # Aveiro
        "03": "PT-02", # Beja
        "04": "PT-03", # Braga
        "05": "PT-04", # Bragança
        "06": "PT-05", # Castelo Branco
        "07": "PT-06", # Coimbra
        "08": "PT-07", # Évora
        "09": "PT-08", # Faro
        "10": "PT-30", # Região Autónoma da Madeira
        "11": "PT-09", # Guarda
        "13": "PT-10", # Leira
        "14": "PT-11", # Lisboa
        "16": "PT-12", # Portalegre
        "17": "PT-13", # Porto
        "18": "PT-14", # Santarém
        "19": "PT-15", # Setúbal
        "20": "PT-16", # Viana do Castelo
        "21": "PT-17", # Vila Real
        "22": "PT-18", # Viseu
        "23": "PT-20", # Região Autónoma dos Açores
      },
      RO: {
        "01": "AB", # Alba
        "02": "AR", # Arad
        "03": "AG", # Argeș
        "04": "BC", # Bacău
        "05": "BH", # Bihar
        "06": "BN", # Bistrița-Năsăud
        "07": "BT", # Botoșani
        "08": "BR", # Brăila
        "09": "BV", # Braşov
        "10": "B", # Bucureşti
        "11": "BZ", # Buzău
        "12": "CS", # Caraş-Severin
        "13": "CJ", # Cluj
        "14": "CT", # Constanța
        "15": "CV", # Covasna
        "16": "DB", # Dâmboviţa
        "17": "DJ", # Dolj
        "18": "GL", # Galaţi
        "19": "GJ", # Gorj
        "20": "HR", # Harghita
        "21": "HD", # Hunedoara
        "22": "IL", # Ialomiţa
        "23": "IS", # Iaşi
        "25": "MM", # Maramureş
        "26": "MH", # Mehedinţi
        "27": "MS", # Mureş
        "28": "NT", # Neamţ
        "29": "OT", # Olt
        "30": "PH", # Prahova
        "31": "SJ", # Sălaj
        "32": "SM", # Satu Mare
        "33": "SB", # Sibiu
        "34": "SV", # Suceava
        "35": "TR", # Teleorman
        "36": "TM", # Timiş
        "37": "TL", # Tulcea
        "38": "VS", # Vaslui
        "39": "VL", # Vâlcea
        "40": "VN", # Vrancea
        "41": "CL", # Călăraşi
        "42": "GR", # Giurgiu
        "43": "IF", # Ilfov
      },
      BR: {
        "01": "AC", # Acre
        "02": "AL", # Alagoas
        "03": "AP", # Amapa
        "04": "AM", # Amazonas
        "05": "BA", # Bahia
        "06": "CE", # Ceara
        "07": "DF", # Distrito Federal
        "08": "ES", # Espirito Santo
        "29": "GO", # Goias
        "13": "MA", # Maranhao
        "14": "MT", # Mato Grosso
        "11": "MS", # Mato Grosso do Sul
        "15": "MG", # Minas Gerais
        "16": "PA", # Para
        "17": "PB", # Paraiba
        "18": "PR", # Parana
        "30": "PE", # Pernambuco
        "20": "PI", # Piaui
        "22": "RN", # Rio Grande do Norte
        "23": "RS", # Rio Grande do Sul
        "21": "RJ", # Rio de Janeiro
        "24": "RO", # Rondonia
        "25": "RR", # Roraima
        "26": "SC", # Santa Catarina
        "27": "SP", # Sao Paulo
        "28": "SE", # Sergipe
        "31": "TO", # Tocantins
      },
      TH: {
        "10": "TH-10", # Bangkok
        "11": "TH-11", # Samut Prakan
        "12": "TH-12", # Nonthaburi
        "13": "TH-13", # Pathum Thani
        "14": "TH-14", # Phra Nakhon Si Ayutthaya
        "15": "TH-15", # Ang Thong
        "16": "TH-16", # Lopburi
        "17": "TH-17", # Sing Buri
        "18": "TH-18", # Chai Nat
        "19": "TH-19", # Saraburi
        "20": "TH-20", # Chon Buri
        "21": "TH-21", # Rayong
        "22": "TH-22", # Chantaburi
        "23": "TH-23", # Trat
        "24": "TH-24", # Chachoengsao
        "25": "TH-25", # Prachin Buri
        "26": "TH-26", # Nakhon Nayok
        "27": "TH-27", # Sa Kaeo
        "30": "TH-30", # Nakhon Ratchasima
        "31": "TH-31", # Buri Ram
        "33": "TH-33", # Si Sa Ket
        "34": "TH-34", # Ubon Ratchathani
        "35": "TH-35", # Yasothon
        "36": "TH-36", # Chaiyaphum
        "37": "TH-37", # Amnat Charoen
        "39": "TH-39", # Nong Bua Lam Phu
        "40": "TH-40", # Khon Kaen
        "41": "TH-41", # Udon Thani
        "42": "TH-42", # Loei
        "43": "TH-43", # Nong Khai
        "44": "TH-44", # Maha Sarakham
        "45": "TH-45", # Roi Et
        "46": "TH-46", # Kalasin
        "47": "TH-47", # Sakon Nakhon
        "48": "TH-48", # Nakhon Phanom
        "49": "TH-49", # Mukdahan
        "50": "TH-50", # Chiang Mai
        "51": "TH-51", # Lamphun
        "52": "TH-52", # Lampang
        "53": "TH-53", # Uttaradit
        "54": "TH-54", # Phrae
        "55": "TH-55", # Nan
        "56": "TH-56", # Phayao
        "57": "TH-57", # Chiang Rai
        "58": "TH-58", # Mae Hong Son
        "60": "TH-60", # Nakhon Sawan
        "61": "TH-61", # Uthai Thani
        "62": "TH-62", # Kamphaeng Phet
        "63": "TH-63", # Tak
        "64": "TH-64", # Sukhothai
        "65": "TH-65", # Phitsanulok
        "66": "TH-66", # Phichit
        "70": "TH-70", # Ratchaburi
        "71": "TH-71", # Kanchanaburi
        "72": "TH-72", # Suphanburi
        "73": "TH-73", # Nakhon Pathom
        "74": "TH-74", # Samut Sakhon
        "75": "TH-75", # Samut Songkhram
        "76": "TH-76", # Phetchaburi
        "77": "TH-77", # Prachuap Khiri Khan
        "80": "TH-80", # Nakhon Si Thammarat
        "81": "TH-81", # Krabi
        "82": "TH-82", # Phang Nga
        "83": "TH-83", # Phuket
        "84": "TH-84", # Surat Thani
        "85": "TH-85", # Ranong
        "86": "TH-86", # Chumphon
        "90": "TH-90", # Songkhla
        "91": "TH-91", # Satun
        "92": "TH-92", # Trang
        "93": "TH-93", # Phatthalung
        "94": "TH-94", # Pattani
        "95": "TH-95", # Yala
        "96": "TH-96", # Narathiwat
      },
    }
  end
end

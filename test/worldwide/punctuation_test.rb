# frozen_string_literal: true

require "test_helper"

module Worldwide
  class PunctuationTest < ActiveSupport::TestCase
    test "end_sentence appends a language-appropriate full stop character (and space if appropriate), if it's not already present" do
      [
        [:en, "The quick brown fox jumped", "The quick brown fox jumped."],
        [:en, "The quick brown fox jumped.", "The quick brown fox jumped."],
        [:en, "The quick brown fox jumped. ", "The quick brown fox jumped."],
        [:en, "The quick brown fox jumped.  ", "The quick brown fox jumped."],
        [:hi, "तेज भूरी लोमड़ी कूद जाती है।", "तेज भूरी लोमड़ी कूद जाती है।"],
        [:hi, "तेज भूरी लोमड़ी कूद जाती है ", "तेज भूरी लोमड़ी कूद जाती है।"],
        [:hi, "तेज भूरी लोमड़ी कूद जाती है। ", "तेज भूरी लोमड़ी कूद जाती है।"],
        [:ja, "速い茶色のキツネがジャンプしました", "速い茶色のキツネがジャンプしました。"],
        [:ja, "速い茶色のキツネがジャンプしました。", "速い茶色のキツネがジャンプしました。"],
        [:th, "สุนัขจิ้งจอกสีน้ำตาลกระโดดอย่างรวดเร็ว", "สุนัขจิ้งจอกสีน้ำตาลกระโดดอย่างรวดเร็ว"],
        [:th, "สุนัขจิ้งจอกสีน้ำตาลกระโดดอย่างรวดเร็ว ", "สุนัขจิ้งจอกสีน้ำตาลกระโดดอย่างรวดเร็ว"],
        ["zh-CN", "敏捷的棕色狐狸跳了起来", "敏捷的棕色狐狸跳了起来。"],
        ["zh-CN", "敏捷的棕色狐狸跳了起来。", "敏捷的棕色狐狸跳了起来。"],
      ].each do |locale, input, expected|
        I18n.with_locale(locale) do
          actual = Worldwide::Punctuation.end_sentence(input)

          assert_equal expected, actual, "Expected #{input.inspect} to convert to #{expected.inspect}"
        end
      end
    end

    test "to_paragraph joins sentences, punctuating and/or adding inter-sentence spacing as needed." do
      [
        [
          :de,
          [
            "Gib einen Nachnamen ein",
            "Wir unterstützen dieses Land / diese Region derzeit nicht. Gib eine neue Adresse ein " \
              "und versuche es erneut.",
            "Gib eine gültige Telefonnummer ein, um diese Zustellmethode zu verwenden",
          ],
          "Gib einen Nachnamen ein. Wir unterstützen dieses Land / diese Region derzeit nicht. Gib eine neue " \
            "Adresse ein und versuche es erneut. Gib eine gültige Telefonnummer ein, um diese Zustellmethode zu " \
            "verwenden.",
        ],
        [
          :en,
          ["Enter a last name", "We don't support this country.", "Enter a phone number"],
          "Enter a last name. We don't support this country. Enter a phone number.",
        ],
        [
          :fr,
          [
            "Saisir un nom",
            "Nous ne prenons pas en charge ce pays/cette région pour le moment. Saisissez une nouvelle adresse.",
            "Saisissez un numéro de téléphone pour ce mode de livraison",
          ],
          "Saisir un nom. Nous ne prenons pas en charge ce pays/cette région pour le moment. " \
            "Saisissez une nouvelle adresse. Saisissez un numéro de téléphone pour ce mode de livraison.",
        ],
        [
          :ja,
          [
            "姓を入力してください",
            "現在この国または地域に対応しておりません。新しい住所を入力して、もう一度お試しください。",
            "この配達方法を使用するには電話番号を入力してください",
          ],
          "姓を入力してください。現在この国または地域に対応しておりません。新しい住所を入力して、" \
            "もう一度お試しください。この配達方法を使用するには電話番号を入力してください。",
        ],
        [
          :th,
          [
            "ป้อนนามสกุล",
            "ในปัจจุบันเรายังไม่รองรับการทำธุรกิจในประเทศ/ภูมิภาคนี้ โปรดป้อนที่อยู่ใหม่แล้วลองอีกครั้ง",
            "ป้อนหมายเลขโทรศัพท์เพื่อใช้วิธีการจัดส่งนี้",
          ],
          "ป้อนนามสกุล ในปัจจุบันเรายังไม่รองรับการทำธุรกิจในประเทศ/ภูมิภาคนี้ โปรดป้อนที่อยู่ใหม่แล้วลองอีกครั้ง " \
            "ป้อนหมายเลขโทรศัพท์เพื่อใช้วิธีการจัดส่งนี้",
        ],
      ].each do |locale, input, expected|
        I18n.with_locale(locale) do
          actual = Worldwide::Punctuation.to_paragraph(input)

          assert_equal expected, actual, "#{locale.inspect} using #{input.inspect} should yield #{expected.inspect}"
        end
      end
    end
  end
end

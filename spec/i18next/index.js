import translationJa from "./locales/ja/translation.json";
import translationEn from "./locales/en/translation.json";

import i18next from "i18next";

await i18next.init({
  lng: "ja",
  debug: true,
  resources: {
    ja: {
      translation: translationJa,
    },
    en: {
      translation: translationEn,
    },
  },
});

const key = i18next.t("key");
const nestedKey = i18next.t("nested.key");

const t = i18next.t;
const shorted = t("key");
const multiline = t(
  // Comment
  "key",
);

document.getElementById("output").innerHTML = [
  key,
  nestedKey,
  shorted,
  multiline,
].join(", ");

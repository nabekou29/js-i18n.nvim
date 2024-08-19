import { t, getFixedT } from "i18next";

t("no-prefix-key-1");
// This key has no prefix. Because, getFixedT does not exist above.

const f = () => {
  const t = getFixedT(null, null, "prefix-1");
  t("prefix-1-key-1");
  // This key prefix is 'prefix-1'. Because it is provided in the most recent getFixedT.

  if (true) {
    const t = getFixedT(null, null, "prefix-2");
    t("prefix-2-key-1");
    // This key prefix is 'prefix-2'. Because it is provided in the most recent getFixedT.
  }

  t("prefix-1-key-2");
  // This key prefix is 'prefix-1'. Although the most recent getFixedT provides 'prefix-2', it is already out of scope,  so ‘prefix-1’ is used instead.

  const f2 = () => {
    const t = getFixedT();
    t("no-prefix-key-2");
    // This key has no prefix. Because, the most recent getFixedT does not provide a prefix.
  };
};

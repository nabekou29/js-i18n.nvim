import { Translation, useTranslation } from "react-i18next";

export const Component1 = () => {
  const { t } = useTranslation();

  return (
    <div>
      {t("no-prefix-key-1")}
      {/* This key has no prefix. Because, useTranslation does not provide a prefix. */}
    </div>
  );
};

export const Component2 = () => {
  const { t } = useTranslation("translation", { keyPrefix: "prefix-1" });

  const key = t("prefix-1-key-1");
  // This key prefix is "prefix-1". Because, it is provided in the most recent useTranslation.

  const InnerComponent1 = () => {
    const { t } = useTranslation();
    return (
      <div>
        {t("no-prefix-key-2")}
        {/* This key has no prefix. Because, the most recent useTranslation does not provide a prefix. */}
      </div>
    );
  };

  const InnerComponent2 = () => {
    const { t } = useTranslation("translation", { keyPrefix: "prefix-2" });
    return (
      <div>
        {t("prefix-2-key-1")}
        {/* This key has prefix "prefix-2". Because, it is provided in the most recent useTranslation. */}
      </div>
    );
  };

  return (
    <>
      <div>
        {t("prefix-1-key-2")}
        {/* This key prefix is "prefix-1". Although the most recent useTranslation provides 'prefix-2', it is already out of scope, so ‘prefix-1’ is used instead. */}
      </div>
      <Translation keyPrefix={"tsl-prefix-1"}>
        {(t) => (
          <div>
            {t("tsl-prefix-1-key-1")}
            {/* This key prefix is "translation-comp-prefix-1". Because, it is provided in the most recent Translation component. */}
          </div>
        )}
      </Translation>
    </>
  );
};

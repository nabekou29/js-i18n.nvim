import { useTranslations } from "next-intl";

export const Component1 = () => {
  const { t } = useTranslations();

  return (
    <div>
      {t("no-prefix-key-1")}
      {/* This key has no prefix. Because, useTranslations does not provide a prefix. */}
    </div>
  );
};

export const Component2 = () => {
  const { t } = useTranslations("prefix-1");

  const key = t("prefix-1-key-1");
  // This key prefix is "prefix-1". Because, it is provided in the most recent useTranslations.

  const InnerComponent1 = () => {
    const { t } = useTranslations();
    return (
      <div>
        {t("no-prefix-key-2")}
        {/* This key has no prefix. Because, the most recent useTranslations does not provide a prefix. */}
      </div>
    );
  };

  const InnerComponent2 = () => {
    const { t } = useTranslations("prefix-2");
    return (
      <div>
        {t("prefix-2-key-1")}
        {/* This key has prefix "prefix-2". Because, it is provided in the most recent useTranslations. */}
      </div>
    );
  };

  return (
    <div>
      {t("prefix-1-key-2")}
      {/* This key prefix is "prefix-1". Although the most recent useTranslations provides "prefix-2", it is already out of scope, so "prefix-1" is used instead. */}
    </div>
  );
};

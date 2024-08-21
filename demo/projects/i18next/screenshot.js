import { useTranslation } from "react-i18next";

export const Component1 = () => {
  const { t } = useTranslation();

  return (
    <div>
      <p>{t("key")}</p>
      <p>{t("nested.key")}</p>
      <Trans i18nKey={"key"} t={t} />
    </div>
  );
};

export const Component2 = () => {
  const { t } = useTranslation("translation", { keyPrefix: "nested" });

  return (
    <div>
      <p>{t("key")}</p>
    </div>
  );
};

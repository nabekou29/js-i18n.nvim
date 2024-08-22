import { useTranslation } from "react-i18next";

export const Component = () => {
  const { t } = useTranslation();
  return <div>{t("key")}</div>;
};

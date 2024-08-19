import { useTranslations } from "next-intl";

export const Component = () => {
  const t = useTranslations();
  return <h1>{t("key")}</h1>;
};

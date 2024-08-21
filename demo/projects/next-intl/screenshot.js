import { useTranslations } from "next-intl";

export const Component1 = () => {
  const t = useTranslations();

  return (
    <div>
      <p>{t("key")}</p>
      <p>{t("nested.key")}</p>
      <p>
        {t.rich("rich-key", {
          highlight: (chunks) => <b>{chunks}</b>,
        })}
      </p>
    </div>
  );
};

export const Component2 = () => {
  const { t } = useTranslations("nested");

  return (
    <div>
      <p>{t("key")}</p>
    </div>
  );
};

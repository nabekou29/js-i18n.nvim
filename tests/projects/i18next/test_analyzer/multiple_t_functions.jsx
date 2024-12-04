import { useTranslation } from "react-i18next";

export const Component1 = () => {
  const { t } = useTranslation("translation", { keyPrefix: "t-prefix" });
  const { t: t2 } = useTranslation("translation", { keyPrefix: "t2-prefix" });

  return (
    <div>
      {t("key")}
      {t2("key")}
    </div>
  );
};

export const Component2 = () => {
  const { t } = useTranslation("translation", { keyPrefix: "t-prefix" });

  const InnerComponent = () => {
    const { t: t2 } = useTranslation("translation", { keyPrefix: "t2-prefix" });
    return (
      <div>
        {t("key")}
        {t2("key")}
      </div>
    );
  };
}

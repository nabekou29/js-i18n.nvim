import React from "react";

import { useTranslations } from "next-intl";

export const Component = (): JSX.Element => {
  const t = useTranslations();
  return <h1>{t("key")}</h1>;
};

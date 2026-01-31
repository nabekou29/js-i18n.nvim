import React, { ReactNode } from "react";

import { useTranslation } from "react-i18next";

export const Component = (): ReactNode => {
  const { t } = useTranslation();
  return <div>{t("exists-key")}</div>;
};

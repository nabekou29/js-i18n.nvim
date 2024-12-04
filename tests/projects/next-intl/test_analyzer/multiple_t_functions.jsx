import { useTranslations } from "next-intl";

export const Component1 = () => {
  const t1 = useTranslations('t1-prefix');
  const t2 = useTranslations('t2-prefix');

  return (
    <div>
      {t1("key")}
      {t2("key")}
    </div>
  );
};

export const Component2 = () => {
  const t1 = useTranslations('t1-prefix');

  const InnerComponent = () => {
    const t2 = useTranslations('t2-prefix');
    return (
      <div>
        {t1("key")}
        {t2("key")}
      </div>
    );
  };
};

export const Component3 = () => {
  const t1 = useTranslations('t1-prefix');
  const t2 = useTranslations('t2-prefix');

  return (
    <div>
      {t1.raw("key")}
      {t2.raw("key")}
    </div>
  );
};

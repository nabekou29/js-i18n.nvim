import { useTranslation } from "react-i18next";

function App() {
  const { t } = useTranslation();
  return (
    <div>
      <h1>{t("title", { name: "John" })}</h1>
      <p>{t("description.part-1")}</p>
      <p>{t("description.part-2")}</p>
    </div>
  );
}

export default App;

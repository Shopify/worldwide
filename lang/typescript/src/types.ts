declare module '*.yml' {
  const data: Record<string, any>;
  export default data;
}

declare module 'custom:regions' {
  // TODO: Use ValidYamlConfig or similar type instead of Record<string, any>
  const data: Record<string, Record<string, any>>;
  export default data;
}

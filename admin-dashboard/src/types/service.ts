export interface AppRouteItem {
  id: string;
  defaultUrl: string;
  titleAr: string;
  titleEn: string;
  descriptionAr: string;
  isUsedInAppUI: boolean;
}

export interface ServiceFirestoreData {
  url?: string;
  title_ar?: string;
}

export interface ServicesLinksDoc {
  services_links?: Record<string, ServiceFirestoreData>;
}

export interface ServiceItemState {
  id: string;
  titleAr: string;
  titleEn: string;
  descriptionAr: string;
  defaultUrl: string;
  currentUrl: string; // Dynamic URL from Firestore or defaultUrl
  customTitleAr?: string;
  isCustomized: boolean; // True if key exists in Firestore services_links
  isUsedInAppUI: boolean;
  inputUrl: string;
  inputTitleAr: string;
  isEditing: boolean;
  isSaving: boolean;
  isReverting: boolean;
  error?: string;
  warning?: string;
  hasUnsavedChanges: boolean;
}

export interface UserAuth {
  uid: string;
  email: string | null;
  isAdmin: boolean;
}

export interface Toast {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
}

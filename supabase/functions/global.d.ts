// Ambient TypeScript declarations for Supabase Edge Functions (Deno runtime)

declare namespace Deno {
  export interface Env {
    get(key: string): string | undefined;
    set(key: string, value: string): void;
    delete(key: string): void;
    toObject(): Record<string, string>;
  }

  export const env: Env;

  export function serve(
    handler: (req: Request) => Response | Promise<Response>
  ): void;
  export function serve(
    options: { port?: number; hostname?: string; onListen?: (params: { port: number; hostname: string }) => void },
    handler: (req: Request) => Response | Promise<Response>
  ): void;
}

declare module 'https://esm.sh/@supabase/supabase-js@2' {
  export function createClient(
    supabaseUrl: string,
    supabaseKey: string,
    options?: any
  ): any;
  export default createClient;
}

declare module 'https://*' {
  const content: any;
  export default content;
  export const createClient: any;
}

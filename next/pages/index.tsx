import { Navbar, Page } from "konsta/react";
import Head from "next/head";
import Image from "next/image";

export default function Home() {
  return (
    <Page>
      <Head>
        <title>Create Next App</title>
        <meta name="description" content="Generated by create next app" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="grid h-screen place-items-center">
        <header >
          <span>
            <Image
              src="/ramune.png"
              alt="TasteNotes logo"
              width={240}
              height={240}
            />
          </span>
        </header>
      </main>
      </Page>
  );
}

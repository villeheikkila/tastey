import {
  getUser,
  supabaseServerClient,
  User,
  withPageAuth,
} from "@supabase/auth-helpers-nextjs";
import Layout from "../components/layout";
import { Database } from "../generated/DatabaseDefinitions";

export default function Activity({
  profile,
}: {
  user: User;
  profile: Database["public"]["Tables"]["profiles"]["Row"];
}) {
  return <Layout title="Activity" username={profile.username}></Layout>;
}

export const getServerSideProps = withPageAuth({
  redirectTo: "/login",
  async getServerSideProps(ctx) {
    const { user } = await getUser(ctx);
    const { data: profile } = await supabaseServerClient(ctx)
      .from("profiles")
      .select("*")
      .match({ id: user.id })
      .single();

    return { props: { profile, user } };
  },
});

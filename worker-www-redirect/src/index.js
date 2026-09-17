/**
 * Sends www.boost-tourism.co to the bare domain with a 301.
 *
 * This lives in a Worker rather than in the site's _redirects file because
 * Cloudflare Pages matches _redirects on path only — a rule written against a
 * full URL never fires, which was verified once www was bound and serving: it
 * returned 200 and the site instead of a redirect.
 *
 * Only the hostname is replaced, so the path, the query string and any fragment
 * survive: www.boost-tourism.co/plans/?x=1 lands on boost-tourism.co/plans/?x=1
 * rather than dumping every visitor on the homepage.
 */
export default {
  fetch(request) {
    const url = new URL(request.url);
    url.hostname = 'boost-tourism.co';
    // 301 so search engines pass ranking across rather than treating the two
    // hostnames as separate copies of the same site.
    return Response.redirect(url.toString(), 301);
  },
};
